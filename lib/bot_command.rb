require 'telegram/bot'
require 'net/http'

module BotCommand
  class Base
    attr_reader :user, :message, :api, :greeting

    def initialize(user, message)
      @user = user
      @message = message
      token = ENV['token']
      @api = ::Telegram::Bot::Api.new(token)
      @greeting = "Привет, меня зовут Мозгва_бот.\nЯ могу показать тебе актуальное расписание на ближайшие игры.\nИли даже зарегистрировать твою команду.\nВот что я умею:\n/game_registration - Регистриция на игру \n/schedule - Расписание игр\n/change_username - Изменить имя (имя используется в качестве имени капитана команды при регистрации)"
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

  #HELP FUNCTION
  #-------------
  #-------------
  #-------------

  class Help < Base
    def should_start?
      text =~ /\A\/help/
    end

    def start
      send_message(@greeting)
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

      send_message("Вы можете поиграть в Мозгву в эти даты: \n" + message + "\nЯ могу зарегистрировать Вас на игру. Только мне надо узнать кто вы новичек или бывалый Мозгвич. Для этого выберите одну из команд \n/new_team (Новая команда)\n /existing_team (Существующая команда)")
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
      send_message("Я могу зарегистрировать Вас на игру. Только мне надо узнать кто вы новичек или бывалый Мозгвич. Для этого выберите одну из команд\n /new_team (Новая команда)\n /existing_team (Существующая команда)")
      user.reset_next_bot_command
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
      url = URI.parse("https://mozgva-staging.herokuapp.com/api/v1/games/schedule?id=11")
      schedule = JSON.parse(Net::HTTP.get(url))
      msg = []
      schedule.each do |key, value|
        value.each do |time|
          msg << key
        end
      end
      msg << "Отменить"
      question = "На какую дату вы хотите зарегистрироваться?"
      send_keyboard(msg, question)
      user.set_next_bot_command('BotCommand::NewTeamDate')
    end
  end

  class NewTeamDate < Base
    def should_start?
      text =~ /(0[1-9]|[12][0-9]|3[01])\.(0[1-9]|1[012])\.(19|20)\d\d/
    end

    def start
      date = text
      url = URI.parse("http://mozgva-staging.herokuapp.com/api/v1/games/schedule?id=11")
      schedule = JSON.parse(Net::HTTP.get(url))
      msg = []
      if schedule[text]
        rd = RegistrationData.new(status: "in progress", date: date)
        user.registration_data.destroy if user.registration_data.present?
        user.registration_data = rd
        user.registration_data.save
        #save date to the game
        #user.current_registration.set_date
        #it sets date
        #it creates user.current_registrations.times << 1), 2) ...

        schedule[text].keys.each_with_index do |time, index|
          rd.games.create(selector: index+1, time: time)
          msg << time
        end
        msg << "Отменить"
        question = "Выберите удобное вам время"
        send_keyboard(msg, question)
        user.set_next_bot_command('BotCommand::NewTeamDateTime')
      else
        send_message("Выберите дату из списка")
      end


    end

    def undefined
      question = "Я понимаю даты только в формате дд.мм.гггг Например ответ '29.06.2017' означает что вы хотите зарегистрироваться на игру 29.06.2017 в Минкульте в 20:00. Что бы зарегистрироваться на Мозгву напишите дату и я зарегистрирую Вас на игру."
      send_keyboard("Отменить", question)
    end
  end

  class NewTeamDateTime < Base
    def should_start?
      text =~ /^([0-9]|0[0-9]|1[0-9]|2[0-3]):[0-5][0-9]$/
    end

    def start
      user.registration_data.games.each do |game|
        game.destroy if game.time != text
      end
      question = "Как будет называться Ваша команда?"
      send_keyboard("Отменить", question)
      user.set_next_bot_command('BotCommand::NewTeamName')
    end

    def undefined
      question = "Я понимаю даты только в формате 1 или 2 и т.д."
      send_keyboard("Отменить", question)
    end
  end

  class NewTeamName < Base
    def should_start?
      text =~ /.+/
    end

    def start
      if team_exists? text
        question = "Такая команда уже существует"
        send_keyboard(["Изменить название", "Перейти к регистрации существующей команды", "Отменить"], question)
        user.set_next_bot_command('BotCommand::AreYouSure')
      else
        user.registration_data.update_attribute(:team_name, text)
        question = "Пожалуйста, подтвердите название вашей команды, вы называетесь #{user.registration_data.team_name}?"
        send_keyboard(["Да", "Изменить название", "Отменить"], question)
        user.set_next_bot_command('BotCommand::AreYouSure')
      end
    end

    def undefined
      question = "Введите название команды еще раз"
      send_keyboard("Отменить", question)
    end

    def team_exists?(team_name)
      response = %x[curl -X GET --header 'Accept: application/json' 'https://mozgva-staging.herokuapp.com/api/v1/teams/find?name=#{team_name}']
      JSON.parse(response)["success"]
    end
  end


  class AreYouSure < Base
    def should_start?
      ["Изменить название", "Да", "Перейти к регистрации существующей команды"].include?(text)
    end

    def start
      if text == "Изменить название"
        question = "Как будет называться Ваша команда?"
        send_keyboard("Отменить", question)
        user.set_next_bot_command('BotCommand::NewTeamName')
      elsif text == "Да"
        question = "Сколько человек в команде? Максимум 9 чел."
        keys = %w(1 2 3 4 5 6 7 8 9 Отменить)
        send_keyboard(keys, question)
        user.set_next_bot_command('BotCommand::TeamMembers')
      elsif text == "Перейти к регистрации существующей команды"
        remove_keyboard("Уже почти")
        user.reset_next_bot_command
      end
    end

    def undefined
      send_message("????")
    end
  end


  class TeamMembers < Base
    def should_start?
      text =~ /^[1-9]$/
    end

    def start
      user.registration_data.update_attribute(:member_amount, text.to_i)

      user.set_next_bot_command('BotCommand::TeamPhone')
      question = "Введите номер капитана в формате 79xxxxxxxxx (11 цифр)"
      send_keyboard("Отменить", question)

    end

    def undefined
      question = "Максимум 9 человек"
      send_keyboard("Отменить", question)
    end
  end




  class TeamPhone < Base
    def should_start?
      text =~ /^[7][9]\d{9}/
    end

    def start
      user.registration_data.update_attribute(:phone, text.to_i)

      response = register_team(user.registration_data)
      status = response["success"]
      message = response["message"]
      
      if status
        message = "Команда #{user.registration_data.team_name} в составе #{user.registration_data.member_amount} чел. зарегистрирована на игру #{user.registration_data.date}, в #{user.registration_data.games.first.time}. Телефон капитана: #{user.registration_data.phone}\nИмя капитана: #{user.nickname || user.last_name}"
        remove_keyboard(message)
        user.reset_next_bot_command
      else
        remove_keyboard(message)
        user.reset_next_bot_command
      end

    end

    def undefined
      question = "Введите номер телефона в формате 79xxxxxxxxx (11 цифр)"
      send_keyboard("Отменить", question)
    end


    def register_team(registration_data)

      endpoint_url = "https://mozgva-staging.herokuapp.com/api/v1/games/booking"
      api_key = "test_bot_api_key"
      date = user.registration_data.date
      id = 11
      time = user.registration_data.games.first.time
      phone = user.registration_data.phone
      captain_name = user.nickname || user.last_name || user.first_name
      persons = user.registration_data.member_amount
      team_name = user.registration_data.team_name


      response = %x[curl -X POST --header 'Content-Type: application/x-www-form-urlencoded' --header 'Accept: application/json' -d 'id=#{id}&date=#{date}&time=#{time}&phone=#{phone}&name=#{captain_name}&persons=#{persons}&api_key=#{api_key}&team_name=#{team_name}' '#{endpoint_url}']

      JSON.parse(response)
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
      user
      send_message(@greeting)
      question = "Могу ли я называть тебя #{user.nickname || (user.first_name.to_s + " " + user.last_name.to_s) }?\n(имя используется в качестве имени капитана команды при регистрации на игру)"
      send_keyboard(%w(Да Нет Отменить), question)
      user.set_next_bot_command('BotCommand::Introduce')
    end
  end


  class UserName < Base
    def should_start?
      text =~ /\A\/change_username/
    end

    def start
      question = "Текущее имя: #{user.nickname || (user.first_name.to_s +" "+ user.last_name.to_s) }\nХочешь изменить его?"
      send_keyboard(%w(Да Нет Отменить), question)
      user.set_next_bot_command('BotCommand::ChangeName')
    end
  end



  class ChangeName < Base
    def should_start?
      text == "Да" || "Нет"
    end

    def start
      if text == "Да"
        question = "Введи свое имя"
        send_keyboard("Отменить", question)
        user.set_next_bot_command('BotCommand::Nickname')
      else
        user.reset_next_bot_command
      end
    end

    def undefined
      question = "Я понимаю только Да или Нет"
      send_keyboard("Отменить", question)
    end
  end


  class Introduce < Base
    def should_start?
      text == "Да" || "Нет"
    end

    def start
      if text == "Да"
        send_message("Приятно познакомиться!")
        user.reset_next_bot_command
      else
        question = "Как тебя зовут?"
        send_keyboard("Отменить", question)
        user.set_next_bot_command('BotCommand::Nickname')
      end
    end

    def undefined
      question = "Я понимаю только Да или Нет"
      send_keyboard("Отменить", question)
    end
  end

  class Nickname < Base
    def should_start?
      text =~ /.+/
    end

    def start
      user.update_attribute(:nickname, text)
      remove_keyboard("Спасибо, #{user.nickname}")      
      user.reset_next_bot_command
    end
  end

  class Cancel < Base
    def should_start?
      true
    end

    def start
      send_message("Отменено")      
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
