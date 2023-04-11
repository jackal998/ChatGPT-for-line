class OpenaiResponseGenerator
  def initialize(messages)
    @messages = messages
  end

  def execute
    response = OpenAI::Client.new.chat(
      parameters: {
        model: "gpt-4",
        messages: @messages
      }
    )

    return_hash = {error: nil, message: "", prompt_tokens: nil, content_tokens: nil}

    if response.dig("error", "code") == "context_length_exceeded"
      return_hash.merge({
        error: "context_length_exceeded",
        prompt_tokens: response.dig("error", "message").scan(/\d+/).last
      })
    elsif response.dig("choices", 0, "finish_reason") == "length"
      return_hash.merge({
        error: "context_length_exceeded",
        prompt_tokens: response.dig("usage", "prompt_tokens")
      })
    elsif response.dig("choices", 0, "message", "content")
      return_hash.merge({
        message: response.dig("choices", 0, "message", "content"),
        prompt_tokens: response.dig("usage", "prompt_tokens"),
        content_tokens: response.dig("usage", "completion_tokens")
      })
    else
      puts "====== request messages to openai: ======"
      puts @messages

      puts "====== response error: ======"
      puts response.dig("error") || response
      raise
    end
  end
end
