# frozen_string_literal: true

RSpec.describe CliDownloaderBot::SessionStore do
  it 'persists session state to json' do
    Dir.mktmpdir do |dir|
      path = File.join(dir, 'sessions.json')
      store = described_class.new(path: path)

      session = store.fetch(42)
      session.transition_to('awaiting_url')
      session.remember_requested_url('https://example.com/test.mp3')
      store.save(session)

      restored = described_class.new(path: path).fetch(42)

      expect(restored.state).to eq('awaiting_url')
      expect(restored.profile['last_requested_url']).to eq('https://example.com/test.mp3')
      expect(restored.history.last['event']).to eq('download_requested')
    end
  end

  it 'recovers from corrupted json by treating it as an empty store' do
    Dir.mktmpdir do |dir|
      path = File.join(dir, 'sessions.json')
      File.write(path, '{broken')
      store = described_class.new(path: path)

      session = store.fetch(11)
      expect(session.state).to eq('idle')

      session.transition_to('awaiting_metadata', 'metadata_step' => 'artist')
      store.save(session)

      restored = described_class.new(path: path).fetch(11)
      expect(restored.state).to eq('awaiting_metadata')
      expect(restored.context['metadata_step']).to eq('artist')
    end
  end
end
