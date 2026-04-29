# frozen_string_literal: true

require 'bundler/setup'
require 'tmpdir'

require_relative '../lib/cli_downloader_bot'

RSpec.configure do |config|
  config.disable_monkey_patching!
  config.expect_with(:rspec) { |c| c.syntax = :expect }
end
