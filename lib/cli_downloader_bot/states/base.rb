# frozen_string_literal: true

module CliDownloaderBot
  module States
    class Base
      attr_reader :bot, :session, :gateway, :intake_service

      def initialize(bot:, session:, gateway:, intake_service:)
        @bot = bot
        @session = session
        @gateway = gateway
        @intake_service = intake_service
      end

      def handle(_message)
        raise NotImplementedError
      end

      private

      def text_for(message)
        message.text.to_s.strip
      end

      def url?(text)
        uri = URI.parse(text)
        uri.is_a?(URI::HTTP) && !uri.host.to_s.empty?
      rescue URI::InvalidURIError
        false
      end

      def command_for(text)
        value = text.to_s.strip
        return value unless value.start_with?('/')

        value.split('@').first
      end

      def send_message(chat_id, text)
        bot.api.send_message(
          chat_id: chat_id,
          text: text,
          reply_markup: Keyboard.main_menu
        )
      end

      def help_text
        <<~TEXT
          Команды каркаса:
          /start - показать меню
          /download - запросить ссылку
          /status - показать статус интеграции
          /reset - сбросить текущее состояние
          /help - показать помощь
        TEXT
      end

      def status_text
        last_url = session.profile['last_requested_url'] || 'пока нет'
        last_file = session.profile['last_downloaded_file'] || 'пока нет'

        <<~TEXT
          Текущее состояние: #{session.state}
          Последняя ссылка: #{last_url}
          Последний файл: #{last_file}
          Интеграция с гемом: #{gateway.description}
        TEXT
      end
    end
  end
end
