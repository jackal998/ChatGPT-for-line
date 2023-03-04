module LineMessage
  class Parser < Base
    def initialize(request)
      @body = request.body.read
      @signature = request.env["HTTP_X_LINE_SIGNATURE"]
    end

    def parse
      unless client.validate_signature(@body, @signature)
        raise "Invalid signature"
      end

      events = client.parse_events_from(@body)

      events.each do |event|
        if event.instance_of?(Line::Bot::Event::Message)
          case event.type
          when Line::Bot::Event::MessageType::Text
            user_id = event["source"]["userId"]
            user_input = event.message["text"]
            reply_token = event["replyToken"]

            return {user_id: user_id, user_input: user_input, reply_token: reply_token}
          end
        end
      end

      raise "No valid user input found"
    end
  end
end
