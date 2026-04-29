# frozen_string_literal: true

require 'time'

module CliDownloaderBot
  class UserSession
    DEFAULT_STATE = 'idle'
    MAX_HISTORY_ITEMS = 20

    attr_reader :chat_id, :context, :profile, :history
    attr_accessor :state

    def self.from_h(chat_id:, data:)
      new(
        chat_id: chat_id,
        state: data.fetch('state', DEFAULT_STATE),
        context: data.fetch('context', {}),
        profile: data.fetch('profile', {}),
        history: data.fetch('history', [])
      )
    end

    def initialize(chat_id:, state: DEFAULT_STATE, context: {}, profile: {}, history: [])
      @chat_id = chat_id.to_s
      @state = state.to_s
      @context = stringify_hash(context)
      @profile = stringify_hash(profile)
      @history = Array(history).map { |item| stringify_hash(item) }
    end

    def transition_to(next_state, context = {})
      @state = next_state.to_s
      @context = stringify_hash(context)
    end

    def reset!
      transition_to(DEFAULT_STATE)
    end

    def remember_requested_url(url)
      profile['last_requested_url'] = url
      append_history('download_requested', url: url)
    end

    def append_history(event, payload = {})
      history << {
        'event' => event,
        'payload' => stringify_hash(payload),
        'at' => Time.now.utc.iso8601
      }
      history.shift while history.size > MAX_HISTORY_ITEMS
    end

    def to_h
      {
        'state' => state,
        'context' => context,
        'profile' => profile,
        'history' => history
      }
    end

    private

    def stringify_hash(object)
      object.each_with_object({}) do |(key, value), result|
        result[key.to_s] = value
      end
    end
  end
end
