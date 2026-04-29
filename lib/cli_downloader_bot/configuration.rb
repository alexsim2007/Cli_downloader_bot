# frozen_string_literal: true

module CliDownloaderBot
  class Configuration
    DEFAULT_STATE_PATH = File.join('storage', 'sessions.json')
    DEFAULT_DOWNLOADS_PATH = 'downloads'

    attr_reader :token, :gem_path, :state_path, :downloads_path, :logger

    def self.from_env(env: ENV, root: Dir.pwd, logger: Logger.new($stdout))
      new(
        token: env['TELEGRAM_BOT_TOKEN'],
        gem_path: env['CLI_DOWNLOADER_GEM_PATH'],
        state_path: env['BOT_STATE_PATH'] || File.join(root, DEFAULT_STATE_PATH),
        downloads_path: env['BOT_DOWNLOADS_PATH'] || File.join(root, DEFAULT_DOWNLOADS_PATH),
        logger: logger
      )
    end

    def initialize(token:, gem_path:, state_path:, downloads_path:, logger:)
      @token = token.to_s.strip
      @gem_path = gem_path.to_s.strip
      @state_path = File.expand_path(state_path)
      @downloads_path = File.expand_path(downloads_path)
      @logger = logger
    end

    def validate!
      raise ConfigurationError, 'TELEGRAM_BOT_TOKEN is missing' if token.empty?

      self
    end

    def gem_path_configured?
      !gem_path.empty?
    end
  end
end
