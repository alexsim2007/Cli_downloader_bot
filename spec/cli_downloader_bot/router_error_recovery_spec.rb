# frozen_string_literal: true

RSpec.describe CliDownloaderBot::Router do
  FakeApi = Struct.new(:messages) do
    def initialize
      super([])
    end

    def send_message(payload)
      messages << payload
    end
  end

  it 'resets persisted state after an unexpected processing error' do
    Dir.mktmpdir do |dir|
      api = FakeApi.new
      store = CliDownloaderBot::SessionStore.new(path: File.join(dir, 'sessions.json'))
      failing_gateway = Class.new do
        def available?
          true
        end

        def description
          'Failing test gateway'
        end

        def download(_url)
          raise StandardError, 'boom'
        end

        def tag_mp3(file_path:, metadata:); end
      end.new
      intake_service = CliDownloaderBot::DownloadIntakeService.new(gateway: failing_gateway)
      processing_service = CliDownloaderBot::FileProcessingService.new(
        gateway: failing_gateway,
        organizer: CliDownloaderBot::Organizer.new(root_path: dir)
      )
      logger = Logger.new(File::NULL)

      router = described_class.new(
        bot: Struct.new(:api).new(api),
        session_store: store,
        gateway: failing_gateway,
        intake_service: intake_service,
        file_processing_service: processing_service,
        logger: logger
      )

      chat = Struct.new(:id).new(40)
      router.handle(Struct.new(:text, :chat).new('/download', chat))
      router.handle(Struct.new(:text, :chat).new('https://example.com/music.mp3', chat))

      expect(store.fetch(40).state).to eq('idle')
      expect(api.messages.last[:text]).to include('State was reset')
    end
  end
end
