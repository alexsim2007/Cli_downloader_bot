# frozen_string_literal: true

RSpec.describe CliDownloaderBot::DownloadIntakeService do
  FakeResult = Struct.new(:file_path, keyword_init: true)

  it 'returns success when the gateway downloads a file' do
    session = CliDownloaderBot::UserSession.new(chat_id: 12)
    gateway = instance_double('Gateway')

    allow(gateway).to receive(:download)
      .with('https://example.com/music.mp3')
      .and_return(FakeResult.new(file_path: '/tmp/downloads/music.mp3'))

    result = described_class.new(gateway: gateway).call(
      session: session,
      url: 'https://example.com/music.mp3'
    )

    expect(result.status).to eq(:success)
    expect(result.file_path).to eq('/tmp/downloads/music.mp3')
    expect(result.message).to include('Загрузка завершена')
    expect(result.message).to include('/tmp/downloads/music.mp3')
    expect(session.profile['last_downloaded_file']).to eq('/tmp/downloads/music.mp3')
    expect(session.history.last['event']).to eq('download_completed')
  end

  it 'returns a readable error when the gateway fails' do
    session = CliDownloaderBot::UserSession.new(chat_id: 13)
    gateway = instance_double('Gateway')

    allow(gateway).to receive(:download)
      .with('https://example.com/music.mp3')
      .and_raise(CliDownloaderBot::DownloaderGateway::DownloadError, 'yt-dlp executable not found')

    result = described_class.new(gateway: gateway).call(
      session: session,
      url: 'https://example.com/music.mp3'
    )

    expect(result.status).to eq(:failed)
    expect(result.message).to include('Не удалось скачать файл')
    expect(result.message).to include('yt-dlp executable not found')
    expect(session.profile['last_requested_url']).to eq('https://example.com/music.mp3')
    expect(session.history.last['event']).to eq('download_failed')
  end
end
