class LineBotController < ApplicationController
  MAX_TOKENS = 1000

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
          user_input = event.message["text"]
          user_id = event["source"]["userId"]

          message_text = generate_response(user_input, user_id)

          # Create a Message record with the user's input and OpenAI's response
          Message.create(user_id: user_id, user_input: user_input, ai_response: message_text)

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

  def generate_response(user_input, user_id)
    # 取得最近 30 分鐘內當前使用者的所有對話
    conversations = Message
      .where(user_id: user_id)
      .where("created_at >= ?", 30.minutes.ago)
      .pluck(:user_input, :ai_response)
      .map { |input, response| "#{input} #{response}" }
  
    # 加入當前傳入的訊息
    conversations << user_input
  
    # 將所有對話合併為一個字串，並限制總長度不超過 1000 個 token
    prompt = conversations.join("\n").split.reverse[0..MAX_TOKENS].reverse.join(" ")
  
    response = OpenAI::Client.new.completions(
      parameters: {
          model: "text-davinci-003",
          prompt: prompt,
          max_tokens: 500
      })
      
    response["choices"][0]["text"].strip
  end
end
