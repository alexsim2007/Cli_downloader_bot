# frozen_string_literal: true

module CliDownloaderBot
  class Router
    attr_reader :bot, :session_store, :gateway, :intake_service, :file_processing_service, :logger

    def initialize(bot:, session_store:, gateway:, intake_service:, file_processing_service:, logger:)
      @bot = bot
      @session_store = session_store
      @gateway = gateway
      @intake_service = intake_service
      @file_processing_service = file_processing_service
      @logger = logger
    end

    def handle(update)
      return unless text_message?(update)

      session = session_store.fetch(update.chat.id)
      state_for(session).handle(update)
      session_store.save(session)
    rescue StandardError => e
      logger.error("router error: #{e.class}: #{e.message}")
      bot.api.send_message(
        chat_id: update.chat.id,
        text: 'Что-то пошло не так. Каркас сбросил состояние.'
      )
    end

    private

    def text_message?(update)
      update.respond_to?(:text) && update.respond_to?(:chat)
    end

    def state_for(session)
      klass = case session.state
              when 'awaiting_metadata' then States::AwaitingMetadata
              when 'awaiting_url' then States::AwaitingUrl
              else States::Idle
              end

      klass.new(
        bot: bot,
        session: session,
        gateway: gateway,
        intake_service: intake_service,
        file_processing_service: file_processing_service
      )
    end
  end
end
