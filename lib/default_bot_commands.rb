require './base'

module DefaultBotCommands

  class Undefined < Base
    def start
      send_message('А вот это я еще не освоил, но я стараюсь')
      send_message('Введи /help чтобы посмотреть, что я уже умею')
    end
  end

  class Cancel < Base
    def should_start?
      true
    end

    def start
      remove_keyboard("Отменено\nЧто бы продолжить нажмите /help")
      user.reset_next_bot_command
    end
  end

end
