class User < ApplicationRecord
validates_uniqueness_of :telegram_id

  def set_next_bot_command(command)
    self.bot_command_data['command'] = command
    save
  end

  def get_next_bot_command
    bot_command_data['command']
  end

  def reset_next_bot_command
    self.bot_command_data = {}
    save
  end

  def self.register_user(user_params)
    user = User.find_or_initialize_by(telegram_id: user_params[:id])
    user.update_attributes!(first_name: user_params[:first_name], last_name: user_params[:last_name])
    user
  end
end
