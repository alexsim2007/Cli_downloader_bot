# frozen_string_literal: true

module CliDownloaderBot
  class Application
    attr_reader :configuration

    def self.from_env
      new(configuration: Configuration.from_env)
    end

    def initialize(configuration:)
      @configuration = configuration
    end

    def run
      configuration.validate!

      session_store = SessionStore.new(path: configuration.state_path)
      gateway = DownloaderGateway.build(gem_path: configuration.gem_path)
      intake_service = DownloadIntakeService.new(gateway: gateway)

      Telegram::Bot::Client.run(configuration.token, logger: configuration.logger) do |bot|
        router = Router.new(
          bot: bot,
          session_store: session_store,
          gateway: gateway,
          intake_service: intake_service,
          logger: configuration.logger
        )

        bot.listen do |update|
          router.handle(update)
        end
      end
    end
  end
end
