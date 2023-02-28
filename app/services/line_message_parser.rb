class LineMessageParser
  def initialize(client)
    @client = client
  end

  def parse(request)
    body = request.body.read
    signature = request.env["HTTP_X_LINE_SIGNATURE"]
    unless @client.validate_signature(body, signature)
      raise "Invalid signature"
    end

    events = @client.parse_events_from(body)

    events.each do |event|
      if event.class == Line::Bot::Event::Message
        case event.type
        when Line::Bot::Event::MessageType::Text
          user_id = event["source"]["userId"]
          user_input = event.message["text"]
          reply_token = event["replyToken"]
        when Line::Bot::Event::MessageType::Image, Line::Bot::Event::MessageType::Video
          # response = client.get_message_content(event.message['id'])
          # tf = Tempfile.open("content")
          # tf.write(response.body)
        end
        
        return {user_id: user_id, user_input: user_input, reply_token: reply_token}
      end
    end

    raise "No valid user input found"
  end
end
