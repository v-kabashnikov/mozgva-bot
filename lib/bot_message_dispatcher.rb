class BotMessageDispatcher
  attr_accessor :command

  def initialize(message)
    @command = message.dig(:message, :text)
    @command = remove_slash if begins_from_slash?
  end

  def begins_from_slash?
    @command.first == "/"
  end

  def remove_slash
    @command[1..-1]
  end

end
