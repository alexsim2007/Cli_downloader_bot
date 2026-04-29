# frozen_string_literal: true

module CliDownloaderBot
  module Keyboard
    module_function

    def main_menu
      Telegram::Bot::Types::ReplyKeyboardMarkup.new(
        keyboard: [
          [{ text: 'Скачать' }, { text: 'Статус' }],
          [{ text: 'Помощь' }, { text: 'Сбросить' }]
        ],
        resize_keyboard: true
      )
    end
  end
end
