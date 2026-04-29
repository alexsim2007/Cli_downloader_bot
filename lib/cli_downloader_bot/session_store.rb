# frozen_string_literal: true

module CliDownloaderBot
  class SessionStore
    attr_reader :path

    def initialize(path:)
      @path = File.expand_path(path)
      ensure_storage!
    end

    def fetch(chat_id)
      data = load_all.fetch(chat_id.to_s, {})
      UserSession.from_h(chat_id: chat_id, data: data)
    end

    def save(session)
      data = load_all
      data[session.chat_id] = session.to_h
      File.write(path, JSON.pretty_generate(data))
    end

    private

    def ensure_storage!
      FileUtils.mkdir_p(File.dirname(path))
      File.write(path, '{}') unless File.exist?(path)
    end

    def load_all
      JSON.parse(File.read(path))
    rescue JSON::ParserError
      {}
    end
  end
end
