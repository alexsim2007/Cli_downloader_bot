# frozen_string_literal: true

RSpec.describe CliDownloaderBot::FileProcessingService do
  FakeTagGateway = Struct.new(:tag_calls) do
    def tag_mp3(file_path:, metadata:)
      tag_calls << { file_path: file_path, metadata: metadata }
    end
  end

  it 'tags mp3 metadata and moves file into artist and album folders' do
    Dir.mktmpdir do |dir|
      source_dir = File.join(dir, 'downloads')
      library_dir = File.join(dir, 'library')
      FileUtils.mkdir_p(source_dir)

      source_file = File.join(source_dir, 'track.mp3')
      File.write(source_file, 'audio')

      session = CliDownloaderBot::UserSession.new(
        chat_id: 44,
        state: 'awaiting_metadata',
        context: {
          'file_path' => source_file,
          'metadata' => {
            'artist' => 'Artist',
            'album' => 'Album',
            'title' => 'Song',
            'year' => '2025'
          }
        }
      )
      gateway = FakeTagGateway.new([])
      organizer = CliDownloaderBot::Organizer.new(root_path: library_dir)

      result = described_class.new(gateway: gateway, organizer: organizer).call(session: session)

      expected_path = File.join(library_dir, 'Artist', 'Album', '2025 - Song.mp3')
      expect(result.status).to eq(:success)
      expect(result.file_path).to eq(expected_path)
      expect(File.exist?(expected_path)).to be(true)
      expect(gateway.tag_calls).to eq(
        [
          {
            file_path: source_file,
            metadata: {
              'artist' => 'Artist',
              'album' => 'Album',
              'title' => 'Song',
              'year' => '2025'
            }
          }
        ]
      )
      expect(session.profile['last_processed_file']).to eq(expected_path)
      expect(session.history.last['event']).to eq('file_processed')
    end
  end

  it 'uses a matching downloaded file when saved path lost the extension' do
    Dir.mktmpdir do |dir|
      source_dir = File.join(dir, 'downloads')
      library_dir = File.join(dir, 'library')
      FileUtils.mkdir_p(source_dir)

      source_file = File.join(source_dir, 'THRILL_PILL_-_Milliony_72911331.mp3')
      File.write(source_file, 'audio')

      session = CliDownloaderBot::UserSession.new(
        chat_id: 45,
        state: 'awaiting_metadata',
        context: {
          'file_path' => File.join(source_dir, '72911331'),
          'metadata' => {
            'artist' => 'THRILL PILL',
            'album' => 'Album',
            'title' => 'Song',
            'year' => '2021'
          }
        }
      )
      gateway = FakeTagGateway.new([])
      organizer = CliDownloaderBot::Organizer.new(root_path: library_dir)

      result = described_class.new(gateway: gateway, organizer: organizer).call(session: session)

      expected_path = File.join(library_dir, 'THRILL PILL', 'Album', '2021 - Song.mp3')
      expect(result.status).to eq(:success)
      expect(result.file_path).to eq(expected_path)
      expect(File.exist?(expected_path)).to be(true)
      expect(gateway.tag_calls.first[:file_path]).to eq(source_file)
    end
  end
end
