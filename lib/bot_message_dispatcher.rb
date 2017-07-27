require 'telegram/bot'
include BotCommand

class BotMessageDispatcher
  attr_reader :message, :user
  COMMANDS = {registration: 'Registration', help: 'Help', start: 'Start'}

  def initialize(message, user)
    @message = message
    @user = user
  end

   def process
    if user.get_next_bot_command
      bot_command = user.get_next_bot_command.safe_constantize.new(user, message)

      if bot_command.should_start?
        bot_command.start
      else
        unknown_command
      end
    else
      command = message.dig(:message, :text)
        if command
          command = message[:message][:text][1..-1]
          if COMMANDS.key?(command.to_sym)
            new_command = eval("BotCommand::#{COMMANDS[command.to_sym]}.new(user, message)")
            new_command.start
          else
            unknown_command
          end
        else
          unknown_command
        end
    end
  end
  
  private

  def unknown_command
    BotCommand::Undefined.new(user, message).start
  end
end