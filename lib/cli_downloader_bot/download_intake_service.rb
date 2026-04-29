# frozen_string_literal: true

module CliDownloaderBot
  class DownloadIntakeService
    Result = Struct.new(:status, :message, :file_path, keyword_init: true)

    attr_reader :gateway

    def initialize(gateway:)
      @gateway = gateway
    end

    def call(session:, url:)
      session.remember_requested_url(url)
      result = gateway.download(url)
      session.profile['last_downloaded_file'] = result.file_path
      session.append_history('download_completed', file_path: result.file_path)

      message = "Загрузка завершена.\n" \
                "Источник: #{url}\n" \
                "Файл сохранен: #{result.file_path}"

      Result.new(status: :success, message: message, file_path: result.file_path)
    rescue DownloaderGateway::DownloadError => e
      session.append_history('download_failed', url: url, error: e.message)
      Result.new(
        status: :failed,
        message: "Не удалось скачать файл.\n#{e.message}"
      )
    end
  end
end
