class AddSecretToRegistrationData < ActiveRecord::Migration[5.1]
  def change
  	add_column :registration_data, :secret, :string
  end
end
