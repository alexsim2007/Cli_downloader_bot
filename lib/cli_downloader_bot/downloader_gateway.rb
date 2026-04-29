# frozen_string_literal: true

module CliDownloaderBot
  class DownloaderGateway
    def self.build(gem_path:)
      return Null.new unless gem_path && !gem_path.empty?

      LocalGem.new(gem_path: gem_path)
    end

    class Null
      def available?
        false
      end

      def description
        'Путь к локальному гему пока не задан.'
      end
    end

    class LocalGem
      attr_reader :gem_path

      def initialize(gem_path:)
        @gem_path = File.expand_path(gem_path)
      end

      def available?
        File.directory?(gem_path) && File.directory?(File.join(gem_path, 'lib'))
      end

      def description
        if available?
          "Локальный гем найден по пути #{gem_path}."
        else
          "Каталог гема не найден по пути #{gem_path}."
        end
      end
    end
  end
end
