# frozen_string_literal: true

module CliDownloaderBot
  module States
    class Idle < Base
      def handle(message)
        text = text_for(message)
        command = command_for(text)
        return if handle_global_command(message, command)

        case command
        when '/start'
          session.reset!
          send_message(message.chat.id, welcome_text)
        when '/download', 'Скачать'
          session.transition_to('awaiting_url')
          send_message(
            message.chat.id,
            'Пришли ссылку на файл или видео. ' \
            'После загрузки я попрошу metadata: artist, album, title, year.'
          )
        when '/status', 'Статус'
          send_message(message.chat.id, status_text)
        else
          handle_unknown(message, text)
        end
      end

      private

      def handle_unknown(message, text)
        if url?(text)
          result = intake_service.call(session: session, url: text)
          begin_metadata_flow(message, result)
          return
        end

        send_message(
          message.chat.id,
          'Нажми «Скачать» или отправь ссылку сразу. ' \
          'Пример: https://example.com/file.mp3'
        )
      end

      def welcome_text
        <<~TEXT
          Бот готов к загрузке файла.

          Сценарий простой: ссылка -> metadata -> готовый файл.
          Нажми «Скачать», чтобы начать.
        TEXT
      end
    end
  end
end
