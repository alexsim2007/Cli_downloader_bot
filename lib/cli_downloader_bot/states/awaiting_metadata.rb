# frozen_string_literal: true

module CliDownloaderBot
  module States
    class AwaitingMetadata < Base
      FIELDS = %w[artist album title year].freeze
      SKIP_VALUES = ['', '-', 'skip', 'пропустить'].freeze

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
          save_value_or_skip(message, text)
        end
      end

      private

      def save_value_or_skip(message, text)
        field = current_field
        metadata = session.context.fetch('metadata', {})
        metadata[field] = text unless skip?(text)

        next_field = FIELDS[FIELDS.index(field) + 1]
        if next_field
          session.transition_to('awaiting_metadata', next_context(metadata, next_field))
          send_message(message.chat.id, metadata_prompt(next_field))
          return
        end

        session.transition_to('awaiting_metadata', next_context(metadata, field))
        result = file_processing_service.call(session: session)
        session.reset!
        send_message(message.chat.id, result.message)
      end

      def current_field
        field = session.context.fetch('metadata_step', FIELDS.first)
        FIELDS.include?(field) ? field : FIELDS.first
      end

      def next_context(metadata, next_field)
        session.context.merge('metadata' => metadata, 'metadata_step' => next_field)
      end

      def skip?(text)
        SKIP_VALUES.include?(text.to_s.strip.downcase)
      end
    end
  end
end
