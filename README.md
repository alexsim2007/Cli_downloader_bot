# CLI Downloader Bot

CLI Downloader Bot is a Ruby Telegram bot project based on the same idea as the `CLI_downloader` gem.

The current version is a foundation for the project, not the final implementation. It already includes a basic bot flow, simple user states, and local persistence for user requests. The actual download and media processing pipeline will be connected later.

## Features

- Telegram bot entrypoint with polling mode
- Basic commands and reply keyboard
- Simple state-based interaction flow
- JSON session persistence
- Local gem path check for future integration
- RSpec setup for the current bot foundation

## Installation

```bash
bundle install
cp .env.example .env
```

Set the required environment variables in `.env`:

```bash
TELEGRAM_BOT_TOKEN=your_bot_token
CLI_DOWNLOADER_GEM_PATH=/Users/al/Documents/Ruby/Ruby_Gem
```

## Quick Start

```bash
bundle exec ruby bin/bot
```

Available commands:

- `/start`: show the main menu
- `/download`: switch to link input mode
- `/status`: show the current bot state
- `/reset`: clear the current user state
- `/help`: show a short help message

You can also send a URL directly. For now the bot stores it as a request and keeps it in the local session data.

## Project Structure

- `bin/bot`: bot entrypoint
- `bin/setup`: local project setup
- `lib/cli_downloader_bot`: application files, router, states, and services
- `storage/`: local JSON persistence
- `spec/`: tests for the current foundation

## Running Tests

```bash
bundle exec rspec
```

## Notes

- The project is intentionally lightweight at this stage.
- Integration with the local gem is prepared, but the real download flow is not connected yet.
- Session data is stored locally in JSON files under `storage/`.
