# frozen_string_literal: true

module CliDownloaderBot
  class FileProcessingService
    Result = Struct.new(:status, :message, :file_path, keyword_init: true)

    attr_reader :gateway, :organizer

    def initialize(gateway:, organizer:)
      @gateway = gateway
      @organizer = organizer
    end

    def call(session:)
      file_path = existing_file_path(session.context.fetch('file_path'))
      metadata = clean_metadata(session.context.fetch('metadata', {}))

      gateway.tag_mp3(file_path: file_path, metadata: metadata) if mp3?(file_path)
      organized_path = organizer.call(file_path: file_path, metadata: metadata)

      session.profile['last_metadata'] = metadata
      session.profile['last_processed_file'] = organized_path
      session.append_history('file_processed', file_path: organized_path, metadata: metadata)

      Result.new(
        status: :success,
        message: success_message(organized_path, metadata),
        file_path: organized_path
      )
    rescue KeyError
      Result.new(
        status: :failed,
        message: 'Не найден скачанный файл для обработки.'
      )
    rescue DownloaderGateway::ProcessingError => e
      failure_result(session, file_path, e)
    rescue StandardError => e
      failure_result(session, file_path, e)
    end

    private

    def clean_metadata(metadata)
      metadata.each_with_object({}) do |(key, value), result|
        text = value.to_s.strip
        result[key.to_s] = text unless text.empty?
      end
    end

    def existing_file_path(file_path)
      path = File.expand_path(file_path)
      return path if File.file?(path)

      fallback = matching_file(path)
      return fallback if fallback

      path
    end

    def matching_file(path)
      directory = File.dirname(path)
      basename = File.basename(path, '.*')
      return nil unless Dir.exist?(directory)

      Dir.children(directory)
         .map { |child| File.join(directory, child) }
         .find { |candidate| File.file?(candidate) && File.basename(candidate).include?(basename) }
    end

    def mp3?(file_path)
      File.extname(file_path).casecmp('.mp3').zero?
    end

    def success_message(file_path, metadata)
      lines = ['Готово: файл обработан.', "Файл: #{file_path}"]
      lines << "Теги: #{metadata_for_message(metadata)}" unless metadata.empty?
      lines.join("\n")
    end

    def failure_result(session, file_path, error)
      session.append_history('file_processing_failed', file_path: file_path, error: error.message)
      Result.new(
        status: :failed,
        message: "Не удалось обработать файл.\n#{error.message}",
        file_path: file_path
      )
    end

    def metadata_for_message(metadata)
      metadata.map { |key, value| "#{key}=#{value}" }.join(', ')
    end
  end
end
