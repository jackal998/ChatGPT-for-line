class OpenaiPromptGenerator
  TOKENS_LIMIT = 3800

  def initialize(user_info)
    @user_info = user_info
  end

  def execute
    total_tokens = 0

    user_messages_with_tokens = Message
      .where(user_id: @user_info[:user_id])
      .where("created_at >= ?", 3.days.ago)
      .order("created_at DESC")
      .each_with_object([]) do |message, arr|
        break arr if total_tokens + message.content_tokens > TOKENS_LIMIT

        total_tokens += message.content_tokens
        arr << {
          message: {role: message.role, content: message.content},
          content_tokens: message.content_tokens
        }
      end

    {
      messages_with_tokens: user_messages_with_tokens.reverse << {
        message: {role: "user", content: @user_info[:user_input]},
        content_tokens: nil
      },
      total_tokens: total_tokens
    }
  end

  def trim_messages(prompt, response)
    latest_content_tokens = response[:prompt_tokens] - prompt[:total_tokens]

    trimed_tokens = 0

    trimed_messages_with_tokens = prompt[:messages_with_tokens].filter_map do |message_with_token|
      trimed_tokens += message_with_token[:content_tokens].to_i
      next if trimed_tokens < latest_content_tokens

      {message: message_with_token[:message], content_tokens: message_with_token[:content_tokens]}
    end

    {
      messages_with_tokens: trimed_messages_with_tokens,
      total_tokens: response[:prompt_tokens] - trimed_tokens
    }
  end
end
