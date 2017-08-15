class CreateGames < ActiveRecord::Migration[5.1]
  def change
    create_table :games do |t|

      t.integer :selector
      t.string :place
      t.string :time
      t.belongs_to :registration_data, index: true
      t.timestamps
    end
  end
end
