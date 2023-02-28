class OpenaiResponseGenerator
  def initialize(prompt)
    @prompt = prompt
  end

  def execute
    response = OpenAI::Client.new.completions(
      parameters: {
        model: "text-davinci-003",
        prompt: @prompt,
        max_tokens: 500
      }
    )

    response["choices"][0]["text"].split("ai_response:").try(:[], 1)
  end
end
