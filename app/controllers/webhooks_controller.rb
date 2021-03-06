class WebhooksController < ApplicationController
  require 'bot_message_dispatcher'
  skip_before_action :verify_authenticity_token

  def callback
    dispatcher.new(webhook, user).process
    render body: nil
  end

  def webhook
    params['webhook']
  end

  def dispatcher
    ::BotMessageDispatcher
  end

  def from
    begin
      webhook.dig(:message, :from) || webhook.dig(:edited_message, :from)
    rescue Exception
      
    end
  end

  def user
    @user ||= User.find_by(telegram_id: from[:id]) || register_user
  end

  def register_user
    @user = User.find_or_initialize_by(telegram_id: from[:id])
    @user.update_attributes!(first_name: from[:first_name], last_name: from[:last_name])
    @user
  end
end