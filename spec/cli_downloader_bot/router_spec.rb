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
      'Test gateway is available.'
    end

    def download(_url)
      result
    end

    def tag_mp3(file_path:, metadata:); end
  end

  FakeProcessingService = Struct.new(:result, :calls) do
    def call(session:)
      calls << {
        file_path: session.context['file_path'],
        metadata: session.context['metadata']
      }
      result
    end
  end

  def build_router(dir:, api:, gateway:, processing_service: nil)
    bot = FakeBot.new(api)
    store = CliDownloaderBot::SessionStore.new(path: File.join(dir, 'sessions.json'))
    intake_service = CliDownloaderBot::DownloadIntakeService.new(gateway: gateway)
    processing_service ||= FakeProcessingService.new(
      CliDownloaderBot::FileProcessingService::Result.new(
        status: :success,
        message: 'Done: file processed.',
        file_path: '/tmp/downloads/music.mp3'
      ),
      []
    )
    logger = Logger.new(File::NULL)

    router = described_class.new(
      bot: bot,
      session_store: store,
      gateway: gateway,
      intake_service: intake_service,
      file_processing_service: processing_service,
      logger: logger
    )

    [router, store, processing_service]
  end

  it 'runs start, link, metadata, result flow and stores the requested url' do
    Dir.mktmpdir do |dir|
      api = FakeApi.new
      gateway = FakeGateway.new(
        Struct.new(:file_path).new('/tmp/downloads/music.mp3')
      )
      processing_service = FakeProcessingService.new(
        CliDownloaderBot::FileProcessingService::Result.new(
          status: :success,
          message: 'Done: file processed.',
          file_path: '/tmp/library/Artist/Album/2025 - Song.mp3'
        ),
        []
      )
      router, store = build_router(
        dir: dir,
        api: api,
        gateway: gateway,
        processing_service: processing_service
      )

      router.handle(FakeMessage.new('/start', FakeChat.new(7)))
      router.handle(FakeMessage.new('/download', FakeChat.new(7)))
      router.handle(FakeMessage.new('https://example.com/music.mp3', FakeChat.new(7)))
      router.handle(FakeMessage.new('Artist', FakeChat.new(7)))
      router.handle(FakeMessage.new('Album', FakeChat.new(7)))
      router.handle(FakeMessage.new('Song', FakeChat.new(7)))
      router.handle(FakeMessage.new('2025', FakeChat.new(7)))

      expect(api.messages.first[:text]).not_to be_empty
      expect(api.messages[2][:text]).to include('Step 1/4')
      expect(api.messages.last[:text]).to include('Done: file processed.')
      expect(processing_service.calls.last[:metadata]).to eq(
        'artist' => 'Artist',
        'album' => 'Album',
        'title' => 'Song',
        'year' => '2025'
      )

      restored = store.fetch(7)
      expect(restored.state).to eq('idle')
      expect(restored.profile['last_requested_url']).to eq('https://example.com/music.mp3')
      expect(restored.profile['last_downloaded_file']).to eq('/tmp/downloads/music.mp3')
    end
  end

  it 'keeps metadata state after restart and resumes from stored context' do
    Dir.mktmpdir do |dir|
      api = FakeApi.new
      gateway = FakeGateway.new(
        Struct.new(:file_path).new('/tmp/downloads/music.mp3')
      )
      processing_service = FakeProcessingService.new(
        CliDownloaderBot::FileProcessingService::Result.new(
          status: :success,
          message: 'Done: file processed.',
          file_path: '/tmp/library/Artist/Unknown Album/Song.mp3'
        ),
        []
      )
      router, store = build_router(
        dir: dir,
        api: api,
        gateway: gateway,
        processing_service: processing_service
      )

      router.handle(FakeMessage.new('/download', FakeChat.new(15)))
      router.handle(FakeMessage.new('https://example.com/music.mp3', FakeChat.new(15)))
      expect(store.fetch(15).state).to eq('awaiting_metadata')

      restarted_router, = build_router(
        dir: dir,
        api: api,
        gateway: gateway,
        processing_service: processing_service
      )
      restarted_router.handle(FakeMessage.new('Artist', FakeChat.new(15)))
      restarted_router.handle(FakeMessage.new('-', FakeChat.new(15)))
      restarted_router.handle(FakeMessage.new('Song', FakeChat.new(15)))
      restarted_router.handle(FakeMessage.new('', FakeChat.new(15)))

      expect(processing_service.calls.last[:metadata]).to eq(
        'artist' => 'Artist',
        'title' => 'Song'
      )
      expect(store.fetch(15).state).to eq('idle')
    end
  end

  it 'handles help and reset while waiting for metadata' do
    Dir.mktmpdir do |dir|
      api = FakeApi.new
      gateway = FakeGateway.new(
        Struct.new(:file_path).new('/tmp/downloads/music.mp3')
      )
      router, store = build_router(dir: dir, api: api, gateway: gateway)

      router.handle(FakeMessage.new('/download', FakeChat.new(20)))
      router.handle(FakeMessage.new('https://example.com/music.mp3', FakeChat.new(20)))
      router.handle(FakeMessage.new('/help', FakeChat.new(20)))
      expect(store.fetch(20).state).to eq('awaiting_metadata')
      expect(api.messages.last[:text]).to include('/reset')

      router.handle(FakeMessage.new('/reset', FakeChat.new(20)))
      expect(store.fetch(20).state).to eq('idle')
    end
  end

  it 'allows checking status while waiting for metadata' do
    Dir.mktmpdir do |dir|
      api = FakeApi.new
      gateway = FakeGateway.new(
        Struct.new(:file_path).new('/tmp/downloads/music.mp3')
      )
      router, store = build_router(dir: dir, api: api, gateway: gateway)

      router.handle(FakeMessage.new('/download', FakeChat.new(21)))
      router.handle(FakeMessage.new('https://example.com/music.mp3', FakeChat.new(21)))
      router.handle(FakeMessage.new('/status', FakeChat.new(21)))

      expect(store.fetch(21).state).to eq('awaiting_metadata')
      expect(api.messages.last[:text]).to include('awaiting_metadata')
    end
  end

  it 'starts a new download from metadata state' do
    Dir.mktmpdir do |dir|
      api = FakeApi.new
      gateway = FakeGateway.new(
        Struct.new(:file_path).new('/tmp/downloads/music.mp3')
      )
      router, store = build_router(dir: dir, api: api, gateway: gateway)

      router.handle(FakeMessage.new('/download', FakeChat.new(25)))
      router.handle(FakeMessage.new('https://example.com/music.mp3', FakeChat.new(25)))
      router.handle(FakeMessage.new('/download', FakeChat.new(25)))

      expect(store.fetch(25).state).to eq('awaiting_url')
    end
  end

  it 'does not break on invalid link or empty input' do
    Dir.mktmpdir do |dir|
      api = FakeApi.new
      gateway = FakeGateway.new(
        Struct.new(:file_path).new('/tmp/downloads/music.mp3')
      )
      router, store = build_router(dir: dir, api: api, gateway: gateway)

      router.handle(FakeMessage.new('/download', FakeChat.new(30)))
      router.handle(FakeMessage.new('not a link', FakeChat.new(30)))
      router.handle(FakeMessage.new('', FakeChat.new(30)))

      expect(store.fetch(30).state).to eq('awaiting_url')
      expect(api.messages.last[:text]).to include('Link is empty')
    end
  end

  it 'repeats year step when year format is invalid' do
    Dir.mktmpdir do |dir|
      api = FakeApi.new
      gateway = FakeGateway.new(
        Struct.new(:file_path).new('/tmp/downloads/music.mp3')
      )
      processing_service = FakeProcessingService.new(
        CliDownloaderBot::FileProcessingService::Result.new(
          status: :success,
          message: 'Done: file processed.',
          file_path: '/tmp/library/Artist/Album/2025 - Song.mp3'
        ),
        []
      )
      router, store = build_router(
        dir: dir,
        api: api,
        gateway: gateway,
        processing_service: processing_service
      )

      router.handle(FakeMessage.new('/download', FakeChat.new(35)))
      router.handle(FakeMessage.new('https://example.com/music.mp3', FakeChat.new(35)))
      router.handle(FakeMessage.new('Artist', FakeChat.new(35)))
      router.handle(FakeMessage.new('Album', FakeChat.new(35)))
      router.handle(FakeMessage.new('Song', FakeChat.new(35)))
      router.handle(FakeMessage.new('20x5', FakeChat.new(35)))

      expect(store.fetch(35).state).to eq('awaiting_metadata')
      expect(store.fetch(35).context['metadata_step']).to eq('year')
      expect(api.messages.last[:text]).to include('Year should contain 4 digits')
      expect(processing_service.calls).to be_empty

      router.handle(FakeMessage.new('2025', FakeChat.new(35)))
      expect(store.fetch(35).state).to eq('idle')
      expect(processing_service.calls.last[:metadata]['year']).to eq('2025')
    end
  end

end
