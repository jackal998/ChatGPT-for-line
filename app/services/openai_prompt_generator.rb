class OpenaiPromptGenerator
  def initialize(user_id, user_input)
    @user_input = user_input
    @user_id = user_id
  end

  def execute
    user_messages = Message
      .where(user_id: @user_id)
      .where("created_at >= ?", 3.days.ago)
      .order(:created_at)
      .pluck(Arel.sql("json_build_object('role', role, 'content', content)"))

    user_messages << {"role" => "user", "content" => @user_input}

    user_messages
  end
end
