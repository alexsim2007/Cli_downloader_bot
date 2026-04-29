# frozen_string_literal: true

module CliDownloaderBot
  module States
    class Idle < Base
      def handle(message)
        text = text_for(message)
        command = command_for(text)

        case command
        when '/start'
          session.reset!
          send_message(message.chat.id, welcome_text)
        when '/help', 'Помощь'
          send_message(message.chat.id, help_text)
        when '/download', 'Скачать'
          session.transition_to('awaiting_url')
          send_message(
            message.chat.id,
            'Пришли ссылку на файл или видео. Бот попробует сразу скачать файл через CLI_downloader.'
          )
        when '/status', 'Статус'
          send_message(message.chat.id, status_text)
        when '/reset', '/cancel', 'Сбросить'
          session.reset!
          send_message(message.chat.id, 'Состояние сброшено. Можно продолжать с чистого шага.')
        else
          handle_unknown(message, text)
        end
      end

      private

      def handle_unknown(message, text)
        if url?(text)
          result = intake_service.call(session: session, url: text)
          session.reset!
          send_message(message.chat.id, result.message)
          return
        end

        send_message(message.chat.id, 'Это стартовый каркас бота. Нажми «Скачать» или отправь ссылку сразу.')
      end

      def welcome_text
        <<~TEXT
          База Telegram-бота готова.
          Сейчас здесь есть меню, состояния, персистентность и подключение к вашему CLI_downloader.

          Нажми «Скачать», чтобы пройти по стартовому сценарию.
        TEXT
      end
    end
  end
end
