require 'telegram/bot'

module BotCommand
  class Base
    attr_accessor :message, :next_command

    def initialize
      @message = "base"
    end

    def all_commands
      res = "Все доступные команды: \n"
      all_commands = BotCommand.constants.select {|c| BotCommand.const_get(c).is_a? Class}
      all_commands.delete(:Undefined)
      all_commands.delete(:Invalid)
      public_commands = all_commands
      public_commands.each do |command|
        res += "/" + command.to_s + "\n"
      end
      res
    end
    #@next_command = nil


  end

  private_constant :Base

  class Undefined < Base

    def initialize
      @message = all_commands
    end

  end

  class First < Base

    def initialize
      @message = "First step"
      @next_command = "BotCommand::Second"
    end
  end

  class Second < Base

    def initialize
      @message = "second"
    end

  end

  class Invalid < Base

    def initialize
      @message = "Invalid command \n" + all_commands
    end
  end

  class Help < Base

    def initialize
      @message = all_commands
    end

  end



end
