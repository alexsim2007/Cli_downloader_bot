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
end
