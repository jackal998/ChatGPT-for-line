module LineMessage
  class Sender < Base
    def initialize(reply_token)
      @reply_token = reply_token
    end

    def send(message_text)
      message = {
        type: "text",
        text: message_text
      }

      client.reply_message(@reply_token, message)
    end
  end
end
