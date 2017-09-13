include BotCommand


class BotActionRouter

  attr_accessor :command, :user

  MASTER_COMMANDS = {cancel: "Cancel"}
  MASTER_COMMANDS.default = "NotFound"

  def initialize(user, command)
    @command = command
    @user = user
  end

  def fetch_action_object
    command = user.get_next_bot_command || command_class_name
    command.safe_constantize || unknown_command
  end

  private

  def command_class_name
    class_name = MASTER_COMMANDS[command.to_sym]
  end

  def unknown_command
    BotCommand::Undefined
  end


end
