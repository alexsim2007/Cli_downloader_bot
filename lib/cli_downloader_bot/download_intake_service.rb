# frozen_string_literal: true

module CliDownloaderBot
  class DownloadIntakeService
    Result = Struct.new(:status, :message, keyword_init: true)

    attr_reader :gateway

    def initialize(gateway:)
      @gateway = gateway
    end

    def call(session:, url:)
      session.remember_requested_url(url)

      message = if gateway.available?
                  "Ссылка сохранена: #{url}\n" \
                    'Каркас проекта уже видит локальный гем. Реальное скачивание подключим следующим шагом.'
                else
                  "Ссылка сохранена: #{url}\n" \
                    'Каркас готов, но путь к гему пока не настроен. ' \
                    'Позже подключим реальное скачивание через CLI_DOWNLOADER_GEM_PATH.'
                end

      Result.new(status: :accepted, message: message)
    end
  end
end
