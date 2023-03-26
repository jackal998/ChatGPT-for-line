class AddIndexOnUserAndTimeToMessages < ActiveRecord::Migration[7.0]
  def change
    add_index :messages, [:user_id, :created_at]
  end
end
