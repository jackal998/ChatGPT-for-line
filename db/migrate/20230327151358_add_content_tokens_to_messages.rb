class AddContentTokensToMessages < ActiveRecord::Migration[7.0]
  def change
    add_column :messages, :content_tokens, :integer

    change_column_null :messages, :content, false
  end
end
