class WebhooksController < ApplicationController
  require 'user_command'
  include BotCommand
  skip_before_action :verify_authenticity_token

  def callback

    user ||= User.find_by_telegram_id user_params[:id] || User.register_user(user_params)
    command = UserCommand.new(message_text, user).command
    BotCommandProceeder.new(user, command).responce

    # data = BotCommand.new(command, user)

    #dispatcher.new(webhook, user).process
    render body: nil
  end

  def webhook
    params['webhook']
  end

  def dispatcher
    ::BotMessageDispatcher
  end

  def from
    webhook[:message][:from]
  end


  def register_user
    @user = User.find_or_initialize_by(telegram_id: from[:id])
    @user.update_attributes!(first_name: from[:first_name], last_name: from[:last_name])
    @user
  end

  def user_request_parser(request)
    binding.pry
  end

  private
  def message
    params.require(:message)
  end

  def message_text
    message.require(:text)
  end

  def user_params
    message.require(:from)
  end
end
