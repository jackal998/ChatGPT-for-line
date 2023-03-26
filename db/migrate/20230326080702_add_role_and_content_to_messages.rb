class AddRoleAndContentToMessages < ActiveRecord::Migration[7.0]
  def change
    rename_column :messages, :user_input, :role
    rename_column :messages, :ai_response, :content
  end
end
