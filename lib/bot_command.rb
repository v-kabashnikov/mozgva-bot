require 'telegram/bot'

module BotCommand
  class Base
    attr_reader :user, :message, :api

    def initialize(user, message)
      @user = user
      @message = message
      token = ENV['token']
      @api = ::Telegram::Bot::Api.new(token)
    end

    def should_start?
      raise NotImplementedError
    end

    def start
      raise NotImplementedError
    end

    protected

    def send_message(text, options={})
      @api.call('sendMessage', chat_id: @user.telegram_id, text: text)
    end

    def text
      @message[:message][:text]
    end

    def from
      @message[:message][:from]
    end
  end

  #HELP FUNCTION
  #-------------
  #-------------
  #-------------

  class Help < Base
    def should_start?
      text =~ /\A\/help/
    end

    def start
      send_message('Сейчас я умею следующее:')
      BotMessageDispatcher::COMMANDS.keys.each do |value|
        send_message("/#{value}")  
      end
      user.reset_next_bot_command
    end
  end

  #DEMO FUNCTION
  #-------------
  #-------------
  #-------------

  class Demo < Base
    def should_start?
      text =~ /\A\/demo/
    end

    def start
      send_message("Привет. Я бот, но тоже очень люблю играть в мозгву")
    end
  end

  #START FUNCTION
  #-------------
  #-------------
  #-------------

  class Start < Base
    def should_start?
      text =~ /\A\/start/
    end

    def start
      send_message('Это мозгва, детка')
      user.reset_next_bot_command
    end
  end

  #UNDEFINED FUNCTION
  #-------------
  #-------------
  #-------------

  class Undefined < Base
    def start
      send_message('А вот это я еще не освоил, но я стараюсь')
      send_message('Введи /help чтобы посмотреть, что я уже умею')
    end
  end
end