class AddUserIdToMessages < ActiveRecord::Migration[7.0]
  def change
    add_column :messages, :user_id, :string
  end
end
