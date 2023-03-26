class OpenaiResponseJob
  include Sidekiq::Worker

  def perform(line_user_info, messages)
    message_text = OpenaiResponseGenerator.new(messages).execute

    LineMessage::Sender.new(line_user_info["reply_token"]).send(message_text)

    Message.insert_all([
      {role: "user", content: line_user_info["user_input"], user_id: line_user_info["user_id"]},
      {role: "assistant", content: message_text, user_id: line_user_info["user_id"]}
    ])
  end
end
