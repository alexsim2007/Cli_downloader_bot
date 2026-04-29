# frozen_string_literal: true

module CliDownloaderBot
  module States
    class AwaitingUrl < Base
      def handle(message)
        text = text_for(message)
        command = command_for(text)
        return if handle_global_command(message, command)

        case command
        when '/start'
          session.reset!
          send_message(
            message.chat.id,
            'Начинаем заново. Нажми «Скачать» или отправь ссылку.'
          )
        else
          accept_or_repeat(message, text)
        end
      end

      private

      def accept_or_repeat(message, text)
        unless url?(text)
          send_message(
            message.chat.id,
            'Я сейчас жду именно ссылку. Пример: https://example.com/file.mp3'
          )
          return
        end

        result = intake_service.call(session: session, url: text)
        begin_metadata_flow(message, result)
      end
    end
  end
end
