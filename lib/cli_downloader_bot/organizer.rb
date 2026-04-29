# frozen_string_literal: true

module CliDownloaderBot
  class Organizer
    attr_reader :root_path

    def initialize(root_path:)
      @root_path = File.expand_path(root_path)
    end

    def call(file_path:, metadata:)
      source = File.expand_path(file_path)
      destination = destination_for(source, metadata)

      FileUtils.mkdir_p(File.dirname(destination))
      return source if source == destination

      FileUtils.mv(source, destination)
      destination
    end

    private

    def destination_for(source, metadata)
      artist = folder_part(metadata['artist'], 'Unknown Artist')
      album = folder_part(metadata['album'], 'Unknown Album')
      title = folder_part(metadata['title'], File.basename(source, '.*'))
      year = metadata['year'].to_s.strip
      extension = File.extname(source)
      filename = year.empty? ? "#{title}#{extension}" : "#{year} - #{title}#{extension}"

      File.join(root_path, artist, album, filename)
    end

    def folder_part(value, fallback)
      cleaned = value.to_s.strip
      cleaned = fallback if cleaned.empty?
      cleaned.gsub(/[<>:"\/\\|?*]/, '_')
    end
  end
end
