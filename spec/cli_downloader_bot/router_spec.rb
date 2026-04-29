# frozen_string_literal: true

RSpec.describe CliDownloaderBot::Router do
  FakeChat = Struct.new(:id)
  FakeMessage = Struct.new(:text, :chat)

  class FakeApi
    attr_reader :messages

    def initialize
      @messages = []
    end

    def send_message(payload)
      messages << payload
    end
  end

  FakeBot = Struct.new(:api)
  FakeGateway = Struct.new(:result) do
    def available?
      true
    end

    def description
      'Тестовый шлюз активен.'
    end

    def download(_url)
      result
    end
  end

  it 'starts download flow and stores the requested url' do
    Dir.mktmpdir do |dir|
      api = FakeApi.new
      bot = FakeBot.new(api)
      store = CliDownloaderBot::SessionStore.new(path: File.join(dir, 'sessions.json'))
      gateway = FakeGateway.new(
        Struct.new(:file_path).new('/tmp/downloads/video.mp4')
      )
      intake_service = CliDownloaderBot::DownloadIntakeService.new(gateway: gateway)
      logger = Logger.new(File::NULL)

      router = described_class.new(
        bot: bot,
        session_store: store,
        gateway: gateway,
        intake_service: intake_service,
        logger: logger
      )

      router.handle(FakeMessage.new('/download', FakeChat.new(7)))
      router.handle(FakeMessage.new('https://example.com/video', FakeChat.new(7)))

      expect(api.messages[0][:text]).to include('Пришли ссылку')
      expect(api.messages[1][:text]).to include('Загрузка завершена')

      restored = store.fetch(7)
      expect(restored.state).to eq('idle')
      expect(restored.profile['last_requested_url']).to eq('https://example.com/video')
      expect(restored.profile['last_downloaded_file']).to eq('/tmp/downloads/video.mp4')
    end
  end

  it 'shows welcome message on start' do
    Dir.mktmpdir do |dir|
      api = FakeApi.new
      bot = FakeBot.new(api)
      store = CliDownloaderBot::SessionStore.new(path: File.join(dir, 'sessions.json'))
      gateway = CliDownloaderBot::DownloaderGateway::Null.new
      intake_service = CliDownloaderBot::DownloadIntakeService.new(gateway: gateway)
      logger = Logger.new(File::NULL)

      router = described_class.new(
        bot: bot,
        session_store: store,
        gateway: gateway,
        intake_service: intake_service,
        logger: logger
      )

      router.handle(FakeMessage.new('/start', FakeChat.new(9)))

      expect(api.messages.last[:text]).to include('База Telegram-бота готова')
    end
  end
end
