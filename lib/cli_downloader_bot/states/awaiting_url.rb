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
            'Starting over. Press download or send a link.'
          )
        else
          accept_or_repeat(message, text)
        end
      end

      private

      def accept_or_repeat(message, text)
        if text.empty?
          send_message(
            message.chat.id,
            'Link is empty. Send a valid URL, for example: https://example.com/file.mp3'
          )
          return
        end

        unless url?(text)
          send_message(
            message.chat.id,
            'I am waiting for a link. Example: https://example.com/file.mp3'
          )
          return
        end

        result = intake_service.call(session: session, url: text)
        begin_metadata_flow(message, result)
      end
    end
  end
end
