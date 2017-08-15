require 'telegram/bot'
require 'net/http'

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
      send_message('Привет, меня зовут Мозгва_бот. Я могу показать тебе актуальное расписание на ближайшие игры. Или даже зарегистрировать твою команду. Вот что я умею:
/game_registration - Регистриция на игру
/schedule - Расписание игр')
      user.reset_next_bot_command
    end
  end

  #SCHEDULE FUNCTION
  #-------------
  #-------------
  #-------------


  class Schedule < Base

    def should_start?
      text =~ /\A\/schedule/
    end

    def start
      url = URI.parse("https://mozgva-staging.herokuapp.com/api/v1/games/schedule?id=11")
      schedule = JSON.parse(Net::HTTP.get(url))
      message = ""
      schedule.each do |key, value|
        value.each do |time|
          message += key + " (" + time.first + " Минкульт)" + "\n"
        end
      end


      send_message("Вы можете поиграть в Мозгву в эти даты: \n" + message + "\n" + "Я могу зарегистрировать Вас на игру. Только мне надо узнать кто вы новичек или бывалый Мозгвич. Для этого выберите одну из команд\n
/new_team (Новая команда)\n
/existing_team (Существующая команда)")
      user.reset_next_bot_command
    end
  end

  #REGISTRATION FUNCTION
  #-------------
  #-------------
  #-------------

  class GameRegistration < Base
    def should_start?
      text =~ /\A\/game_registration/
    end

    def start
      send_message("Я могу зарегистрировать Вас на игру. Только мне надо узнать кто вы новичек или бывалый Мозгвич. Для этого выберите одну из команд\n
/new_team (Новая команда)\n
/existing_team (Существующая команда)")
      user.reset_next_bot_command
      # user.set_next_bot_command('BotCommand::Next')
    end

    def undefined
    end
  end

  #NEW TEAM FUNCTION
  #-------------
  #-------------
  #-------------

  class NewTeam < Base
    def should_start?
      text =~ /\A\/new_team/
    end

    def start
      url = URI.parse("https://mozgva.com/api/v1/games/schedule?id=1")
      schedule = JSON.parse(Net::HTTP.get(url))
      msg = []
      schedule.each do |key, value|
        value.each do |time|
          msg << key
        end
      end
      question = "На какую дату вы хотите зарегистрироваться?"
        answers =
        Telegram::Bot::Types::ReplyKeyboardMarkup
        .new(keyboard: msg, one_time_keyboard: true)
        @api.call('sendMessage', chat_id: @user.telegram_id, text: question, reply_markup: answers)
        user.set_next_bot_command('BotCommand::NewTeamDate')
    end
  end

  class NewTeamDate < Base
    def should_start?
      text =~ /(0[1-9]|[12][0-9]|3[01])\.(0[1-9]|1[012])\.(19|20)\d\d/
    end

    def start
      date = message[:message][:text]
      url = URI.parse("http://mozgva-staging.herokuapp.com/api/v1/games/schedule?id=11")
      schedule = JSON.parse(Net::HTTP.get(url))
      msg = []
      if schedule[message[:message][:text]]
        rd = RegistrationData.new(status: "in progress", date: date)
        user.registration_data.destroy if user.registration_data.present?
        user.registration_data = rd
        user.registration_data.save
        #save date to the game
        #user.current_registration.set_date
        #it sets date
        #it creates user.current_registrations.times << 1), 2) ...

        schedule[message[:message][:text]].keys.each_with_index do |time, index|
          rd.games.create(selector: index+1, time: time)
          msg << time
        end
        question = "Выберите удобное вам время"
        answers =
        Telegram::Bot::Types::ReplyKeyboardMarkup
        .new(keyboard: msg, one_time_keyboard: true)
        @api.call('sendMessage', chat_id: @user.telegram_id, text: question, reply_markup: answers)
        user.set_next_bot_command('BotCommand::NewTeamDateTime')
      else
        send_message("Выберите дату из списка")
      end


    end

    def undefined
      send_message("Я понимаю даты только в формате дд.мм.гггг Например ответ '29.06.2017' означает что вы хотите зарегистрироваться на игру 29.06.2017 в Минкульте в 20:00. Что бы зарегистрироваться на Мозгву напишите дату и я зарегистрирую Вас на игру.")
    end
  end

  class NewTeamDateTime < Base
    def should_start?
      true
    end

    def start
      user.registration_data.games.each do |game|
        game.destroy if game.time != message[:message][:text]
      end
      send_message("Как будет называться Ваша команда?")
      user.set_next_bot_command('BotCommand::NewTeamName')
    end

    def undefined
      send_message("Я понимаю даты только в формате 1 или 2 и т.д.")
    end
  end

  class NewTeamName < Base
    def should_start?
      text =~ /.+/
    end

    def start
      user.registration_data.update_attribute(:team_name, message[:message][:text])
      question = "Пожалуйста, подтвердите название Вашей команды, вы называетесь #{user.registration_data.team_name}?"
      answers = Telegram::Bot::Types::ReplyKeyboardMarkup
                .new(keyboard: ["Да", "Изменить название"], one_time_keyboard: true)

      @api.call('sendMessage', chat_id: @user.telegram_id, text: question, reply_markup: answers)

      user.set_next_bot_command('BotCommand::AreYouSure')
    end

    def undefined
      send_message("Введите название команды еще раз")
    end
  end


  class AreYouSure < Base
    def should_start?
      text == "Да" || "Изменить название"
    end

    def start
      if message[:message][:text] == "Изменить название"
        send_message("Как будет называться Ваша команда?")
        user.set_next_bot_command('BotCommand::NewTeamName')
      else
        send_message("Сколько человек в команде? Максимум 9 чел.")
        user.set_next_bot_command('BotCommand::TeamMembers')
      end
    end

    def undefined
      send_message("Введите + или -")
    end
  end


  class TeamMembers < Base
    def should_start?
      text =~ /[0-9]/
    end

    def start
      user.registration_data.update_attribute(:member_amount, message[:message][:text].to_i)

      user.set_next_bot_command('BotCommand::TeamPhone')
      send_message("Введите номер капитана")

    end

    def undefined
      send_message("Введите + или -")
    end
  end




  class TeamPhone < Base
    def should_start?
      text =~ /[0-9]/
    end

    def start
      user.registration_data.update_attribute(:phone, message[:message][:text].to_i)



      response = register_team(user.registration_data)
      binding.pry

      send_message("Команда #{user.registration_data.team_name} в составе #{user.registration_data.member_amount} чел. зарегистрирована на игру #{user.registration_data.date}, в #{user.registration_data.games.first.time}. Телефон капитана: #{user.registration_data.phone}")
      user.reset_next_bot_command

    end

    def undefined
      send_message("Введите номер телефона")
    end


    def register_team(registration_data)

      uri = URI.parse("https://mozgva-staging.herokuapp.com/api/v1/games/booking")
      header = {'Content-Type': 'application/json'}
      data = {id: 11, date: "17.08.2017", time: "20:00", phone: "79061111111", persons: "8", api_key: "test_bot_api_key", team_name: "asd"}

      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      request = Net::HTTP::Post.new(uri.request_uri, header)
      request.body = data.to_json

      response = http.request(request)
    end
  end



  class Next < Base
    def should_start?
      text =~ /\A\/next/
    end

    def start
      send_message("Next step")
      user.reset_next_bot_command
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
