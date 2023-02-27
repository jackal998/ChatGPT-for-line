class CreateMessages < ActiveRecord::Migration[7.0]
  def change
    create_table :messages do |t|
      t.string :user_input
      t.string :ai_response

      t.timestamps
    end
  end
end
