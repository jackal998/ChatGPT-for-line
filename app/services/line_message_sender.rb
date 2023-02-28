class LineMessageSender
  def initialize(client, replyToken)
    @client = client
    @replyToken = replyToken
  end

  def send(message_text)
    message = {
      type: "text",
      text: message_text
    }

    @client.reply_message(@replyToken, message)
  end
end
