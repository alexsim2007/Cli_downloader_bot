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

  it 'starts download flow and stores the requested url' do
    Dir.mktmpdir do |dir|
      api = FakeApi.new
      bot = FakeBot.new(api)
      store = CliDownloaderBot::SessionStore.new(path: File.join(dir, 'sessions.json'))
      gateway = CliDownloaderBot::DownloaderGateway::LocalGem.new(gem_path: '/tmp/unknown-gem')
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
      expect(api.messages[1][:text]).to include('Ссылка сохранена')

      restored = store.fetch(7)
      expect(restored.state).to eq('idle')
      expect(restored.profile['last_requested_url']).to eq('https://example.com/video')
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
