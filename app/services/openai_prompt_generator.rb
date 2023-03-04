class OpenaiPromptGenerator
  MAX_TOKENS = 1000

  def initialize(user_id, user_input)
    @user_input = user_input
    @user_id = user_id
  end

  def execute
    # 取得最近 30 分鐘內當前使用者的所有對話
    conversations = Message
      .where(user_id: @user_id)
      .where("created_at >= ?", 30.minutes.ago)
      .pluck(:user_input, :ai_response)
      .map { |input, response| "user_input:#{input}\nai_response:#{response}" }

    # 加入當前傳入的訊息
    conversations << "user_input:#{@user_input}"

    # 將所有對話合併為一個字串，並限制總長度不超過 1000 個 token
    conversations.join("\n").split.reverse[0..MAX_TOKENS].reverse.join(" ")
  end
end
