require 'telegram/bot'

class BotCommandProceeder
  include BotCommand

  attr_reader :user, :command, :api

  def initialize(user, command)
    @user = user
    @command = command
    token = ENV['token']
    @api = ::Telegram::Bot::Api.new(token)
  end

  def responce
    bot_command = eval("BotCommand::#{command.to_s}.new")
    send_message(bot_command.message)
    binding.pry
    if bot_command.next_command.present?
      user.set_next_bot_command(bot_command.next_command)  #BotCommand::Next
    else
      user.reset_next_bot_command
    end
  end

  private

  def send_message(text, options={})
    @api.call('sendMessage', chat_id: @user.telegram_id, text: text)
  end

end
