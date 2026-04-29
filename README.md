# CLI Downloader Bot

CLI Downloader Bot is a Ruby Telegram bot project based on the same idea as the `CLI_downloader` gem.

The current version is still a project foundation, but it already connects the bot flow to the local `CLI_downloader` gem. The bot can accept a link, run the downloader, and keep simple local persistence for user requests.

## Features

- Telegram bot entrypoint with polling mode
- Basic commands and reply keyboard
- Simple state-based interaction flow
- JSON session persistence
- File download through the local `CLI_downloader` gem
- RSpec setup for the current bot foundation

## Installation

macOS / Linux:

```bash
bundle install
cp .env.example .env
```

Windows PowerShell:

```powershell
bundle install
Copy-Item .env.example .env
```

Set the required environment variables in `.env`:

```bash
TELEGRAM_BOT_TOKEN=your_bot_token
CLI_DOWNLOADER_GEM_PATH=/Users/al/Documents/Ruby/Ruby_Gem
BOT_DOWNLOADS_PATH=downloads
```

Windows example:

```bash
TELEGRAM_BOT_TOKEN=your_bot_token
CLI_DOWNLOADER_GEM_PATH=C:/Users/username/Documents/Ruby/Ruby_Gem
BOT_DOWNLOADS_PATH=downloads
```

You can use forward slashes in the Windows path to avoid escaping backslashes in `.env`.

## Quick Start

```bash
bundle exec ruby bin/bot
```

The same command works in macOS, Linux, and Windows PowerShell.

Available commands:

- `/start`: show the main menu
- `/download`: switch to link input mode
- `/status`: show the current bot state
- `/reset`: clear the current user state
- `/help`: show a short help message

You can also send a URL directly. The bot will try to download it right away and keep the result in the local session data.

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
- The bot saves downloaded files into the directory from `BOT_DOWNLOADS_PATH`.
- Session data is stored locally in JSON files under `storage/`.
- For Windows, make sure Ruby and Bundler are available in `PATH` before running the bot.
