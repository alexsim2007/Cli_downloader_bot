# frozen_string_literal: true

require 'json'
require 'logger'
require 'fileutils'
require 'uri'

require 'telegram/bot'

module CliDownloaderBot
  class Error < StandardError; end
  class ConfigurationError < Error; end
end

require_relative 'cli_downloader_bot/version'
require_relative 'cli_downloader_bot/configuration'
require_relative 'cli_downloader_bot/user_session'
require_relative 'cli_downloader_bot/session_store'
require_relative 'cli_downloader_bot/downloader_gateway'
require_relative 'cli_downloader_bot/download_intake_service'
require_relative 'cli_downloader_bot/keyboard'
require_relative 'cli_downloader_bot/states/base'
require_relative 'cli_downloader_bot/states/idle'
require_relative 'cli_downloader_bot/states/awaiting_url'
require_relative 'cli_downloader_bot/router'
require_relative 'cli_downloader_bot/application'
