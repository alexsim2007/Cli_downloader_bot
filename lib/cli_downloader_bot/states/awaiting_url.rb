# frozen_string_literal: true

module CliDownloaderBot
  module States
    class AwaitingUrl < Base
      def handle(message)
        text = text_for(message)
        command = command_for(text)

        case command
        when '/reset', '/cancel', 'Сбросить'
          session.reset!
          send_message(message.chat.id, 'Окей, отменил текущий шаг. Можем начать заново.')
        when '/help', 'Помощь'
          send_message(message.chat.id, help_text)
        else
          accept_or_repeat(message, text)
        end
      end

      private

      def accept_or_repeat(message, text)
        unless url?(text)
          send_message(message.chat.id, 'Я сейчас жду именно ссылку. Пример: https://example.com/file.mp3')
          return
        end

        result = intake_service.call(session: session, url: text)
        session.reset!
        send_message(message.chat.id, result.message)
      end
    end
  end
end
