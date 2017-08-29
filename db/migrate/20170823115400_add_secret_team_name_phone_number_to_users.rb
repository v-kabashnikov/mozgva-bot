class AddSecretTeamNamePhoneNumberToUsers < ActiveRecord::Migration[5.1]
  def change
    add_column :users, :secret, :string
    add_column :users, :phone_number, :string
    add_column :users, :team_name, :string
  end
end
