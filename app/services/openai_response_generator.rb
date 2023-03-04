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

    origin_ai_response, prefixed_ai_response =
      response["choices"][0]["text"].strip.split("ai_response:")

    prefixed_ai_response || origin_ai_response
  end
end
