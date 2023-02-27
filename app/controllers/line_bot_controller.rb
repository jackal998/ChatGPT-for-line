class LineBotController < ApplicationController
  def callback
    body = request.body.read
    signature = request.env["HTTP_X_LINE_SIGNATURE"]
    unless client.validate_signature(body, signature)
      head :bad_request
    end
 
    events = client.parse_events_from(body)
 
    events.each do |event|
      case event
      when Line::Bot::Event::Message
        case event.type
        when Line::Bot::Event::MessageType::Text
          reply_token = event["replyToken"]
          text = event.message["text"]
          user_id = event["source"]["userId"]

          response = OpenAI::Client.new.completions(
            parameters: {
                model: "text-davinci-003",
                prompt: text,
                max_tokens: 50
            })

          message_text = response["choices"][0]["text"].strip

          # Create a Message record with the user's input and OpenAI's response
          Message.create(user_id: user_id, user_input: text, ai_response: message_text)

          message = {
            type: "text",
            text: message_text
          }
 
          client.reply_message(event["replyToken"], message)
        end
      end
    end
 
    head :ok
  end
 
  private
 
  def client
    @client ||= Line::Bot::Client.new { |config|
      config.channel_secret = ENV["LINE_CHANNEL_SECRET"]
      config.channel_token = ENV["LINE_CHANNEL_TOKEN"]
    }
  end
end
