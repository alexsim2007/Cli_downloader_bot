# frozen_string_literal: true

module CliDownloaderBot
  module States
    class Base
      attr_reader :bot, :session, :gateway, :intake_service, :file_processing_service

      def initialize(bot:, session:, gateway:, intake_service:, file_processing_service:)
        @bot = bot
        @session = session
        @gateway = gateway
        @intake_service = intake_service
        @file_processing_service = file_processing_service
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

      def handle_global_command(message, command)
        case command
        when '/help', 'Помощь'
          send_message(message.chat.id, help_text)
          true
        when '/reset', '/cancel', 'Сбросить'
          session.reset!
          send_message(
            message.chat.id,
            'Состояние сброшено. Можно начать заново.'
          )
          true
        when '/download', 'Скачать'
          session.transition_to('awaiting_url')
          send_message(
            message.chat.id,
            'Пришли ссылку на файл или видео.'
          )
          true
        else
          false
        end
      end

      def begin_metadata_flow(message, result)
        if result.status == :failed
          session.reset!
          send_message(message.chat.id, result.message)
          return
        end

        session.transition_to(
          'awaiting_metadata',
          'file_path' => result.file_path,
          'metadata' => {},
          'metadata_step' => 'artist'
        )

        send_message(
          message.chat.id,
          "#{result.message}\n\n#{metadata_prompt('artist')}"
        )
      end

      def metadata_prompt(field)
        labels = {
          'artist' => 'artist',
          'album' => 'album',
          'title' => 'title',
          'year' => 'year'
        }

        "Отправь #{labels.fetch(field)} или '-' чтобы пропустить."
      end

      def help_text
        <<~TEXT
          Команды:
          /start - показать меню
          /download - отправить ссылку на файл
          /status - показать статус
          /reset - сбросить текущее состояние
          /help - показать помощь

          Сценарий: /start -> /download -> ссылка -> metadata -> result.
          В metadata можно пропустить поле символом "-".
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
