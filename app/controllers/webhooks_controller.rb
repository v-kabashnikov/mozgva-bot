class WebhooksController < ApplicationController
  require 'bot_action_router'
  require 'bot_message_dispatcher'
  skip_before_action :verify_authenticity_token

  def callback
    command = BotMessageDispatcher.new(webhook).command
    action_object = BotActionRouter.new(user, command).fetch_action_object
    bot_command = action_object.new(user, webhook)
    if bot_command.should_start?
      bot_command.start
    else
      bot_command.undefined
    end
    render body: nil
  end

  def webhook
    params['webhook']
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
