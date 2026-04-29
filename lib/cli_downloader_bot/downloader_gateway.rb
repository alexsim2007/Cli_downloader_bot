# frozen_string_literal: true

module CliDownloaderBot
  class DownloaderGateway
    class DownloadError < Error; end

    def self.build(gem_path:, output_directory:)
      return Null.new if gem_path.to_s.strip.empty?

      LocalGem.new(gem_path: gem_path, output_directory: output_directory)
    end

    class Null
      def available?
        false
      end

      def description
        'Путь к локальному гему пока не задан.'
      end

      def download(_url)
        raise DownloadError, 'Не задан CLI_DOWNLOADER_GEM_PATH.'
      end
    end

    class LocalGem
      attr_reader :gem_path, :output_directory

      def initialize(gem_path:, output_directory:)
        @gem_path = File.expand_path(gem_path)
        @output_directory = File.expand_path(output_directory)
      end

      def available?
        File.file?(entrypoint_path)
      end

      def description
        if available?
          "Локальный гем найден по пути #{gem_path}."
        else
          "Каталог гема не найден по пути #{gem_path}."
        end
      end

      def download(url)
        ensure_available!

        result = fetcher.download(url)
        raise DownloadError, 'Гем не вернул путь к скачанному файлу.' if result.file_path.to_s.strip.empty?

        result
      rescue LoadError, NameError => e
        raise DownloadError, "Не удалось подключить CLI_downloader: #{e.message}"
      rescue DownloadError
        raise
      rescue StandardError => e
        raise DownloadError, e.message
      end

      private

      def ensure_available!
        return if available?

        raise DownloadError, "CLI_downloader gem was not found at #{gem_path}"
      end

      def fetcher
        @fetcher ||= begin
          load_client!
          client_namespace::Fetcher.new(output_directory: output_directory)
        end
      end

      def load_client!
        return if defined?(::CLIDownloader::Fetcher)

        lib_path = File.join(gem_path, 'lib')
        $LOAD_PATH.unshift(lib_path) unless $LOAD_PATH.include?(lib_path)
        require 'CLI_downloader'
      end

      def client_namespace
        Object.const_get(:CLIDownloader)
      end

      def entrypoint_path
        File.join(gem_path, 'lib', 'CLI_downloader.rb')
      end
    end
  end
end
