class OpenaiResponseGenerator
  def initialize(messages)
    @messages = messages
  end

  def execute
    response = OpenAI::Client.new.chat(
      parameters: {
        model: "gpt-3.5-turbo",
        messages: @messages
      }
    )

    response.dig("choices", 0, "message", "content")
  end
end
