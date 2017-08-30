module BotActionRouter

  attr_accessor :command

  MASTER_COMMANDS = {cancel: "Cancel"}
  MASTER_COMMANDS.default = "NotFound"

  def fetch_action_object(command)
    @command = command
    eval("BotCommand::#{command_class_name}")
  end


  def command_class_name(command)
    if command.present?
      action_class = fetch_command_object_class_name(command)
    else
      unproper_input_warning
    end
  end

  def fetch_command_object_class_name(command)
    command = remove_slash(command) if begins_from_slash?(command)
    class_name = MASTER_COMMANDS.values_at(command.to_sym)
  end

  def unproper_input_warning
    eval("BotCommand::UnproperInput")
  end

  def begins_from_slash?(command)
    command.first == "/"
  end

  def remove_slash(command)
    command[1..-1]
  end

end
