class CreateRegistrationData < ActiveRecord::Migration[5.1]
  def change
    create_table :registration_data do |t|


      t.string :date
      t.string :team_name
      t.string :status
      t.integer :member_amount
      t.belongs_to :user, index: true

      t.timestamps
    end
  end
end
