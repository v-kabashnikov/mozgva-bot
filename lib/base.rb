class Base
    attr_reader :user, :message, :api, :greeting

    def initialize(user, message)
      @user = user
      @message = message
      token = ENV['token']
      @api = ::Telegram::Bot::Api.new(token)
      @greeting = "Привет, меня зовут Мозгва_бот.\nЯ могу показать тебе актуальное расписание на ближайшие игры.\nИли даже зарегистрировать твою команду.\nВот что я умею:\n/game_registration - Регистриция на игру \n/schedule - Расписание игр\n/settings - Персональные настройки (Имя, название команды, секретный код, номер телефона. Используются при регистрации)"
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

    def send_keyboard(buttons, question, options={})
      question = question
      answers =
        Telegram::Bot::Types::ReplyKeyboardMarkup
        .new(keyboard: buttons, one_time_keyboard: true)
      @api.call('sendMessage', chat_id: @user.telegram_id, text: question, reply_markup: answers)
    end

    def send_button(text, question, options={})
      button =
        Telegram::Bot::Types::KeyboardButton
        .new(text: text)
      @api.call('sendMessage', chat_id: @user.telegram_id, text: question, reply_markup: button)
    end

    def remove_keyboard(text)
      kb = Telegram::Bot::Types::ReplyKeyboardRemove.new(remove_keyboard: true)
      @api.call('sendMessage', chat_id: @user.telegram_id, text: text, reply_markup: kb)
    end

    def text
      @message[:message][:text]
    end

    def from
      @message[:message][:from]
    end
  end
