class UserCommand
  include BotCommand
  include ActiveModel::Validations
  attr_reader :command, :message_text, :user
  validates :message_text, presence: true, format: { with: /\/(\w+)/, allow_blank: false }

  def initialize(message_text, user)
    @message_text = message_text
    @user = user
    @command = set_command
  end

  private

  def set_command
    if valid?
      user.get_next_bot_command || find_command
    else
      :Invalid
    end
  end

  def find_command
    commands = BotCommand.constants.select {|c| BotCommand.const_get(c).is_a? Class}
    commands.find {|command| command == bot_command_class} || :Undefined
  end

  def bot_command_class
    message_text[1..-1].to_sym.capitalize
  end
end
