class OpenaiResponseJob
  include Sidekiq::Worker

  def perform(line_user_info, messages)
    message_text = OpenaiResponseGenerator.new(messages).execute

    LineMessage::Sender.new(line_user_info["reply_token"]).send(message_text)

    Message.create(ai_response: message_text, **line_user_info.slice("user_id", "user_input"))
  end
end
