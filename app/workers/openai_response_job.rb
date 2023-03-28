class OpenaiResponseJob
  include Sidekiq::Worker

  def perform(user_info)
    user_info.deep_symbolize_keys!
    prompt_generator = OpenaiPromptGenerator.new(user_info)

    prompt = prompt_generator.execute
    response = get_response(prompt)

    if response[:error] == "context_length_exceeded"
      prompt = prompt_generator.trim_messages(prompt, response)
      response = get_response(prompt)
    end

    LineMessage::Sender.new(user_info[:reply_token]).send(response[:message])

    Message.insert_all([
      {role: "user", content: user_info[:user_input], user_id: user_info[:user_id], content_tokens: response[:prompt_tokens] - prompt[:total_tokens]},
      {role: "assistant", content: response[:message], user_id: user_info[:user_id], content_tokens: response[:content_tokens]}
    ])
  end

  private

  def get_response(prompt)
    OpenaiResponseGenerator.new(prompt[:messages_with_tokens].pluck(:message)).execute
  end
end
