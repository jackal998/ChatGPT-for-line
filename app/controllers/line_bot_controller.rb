class LineBotController < ApplicationController
  MAX_TOKENS = 1000

  def callback
    parsed_line_message = LineMessageParser.new(line_client).parse(request)

    prompt = OpenaiPromptGenerator.new(*parsed_line_message.values_at(:user_id, :user_input)).execute
    message_text = OpenaiResponseGenerator.new(prompt).execute

    LineMessageSender.new(line_client, parsed_line_message[:reply_token]).send(message_text)

    Message.create(ai_response: message_text, **parsed_line_message.slice(:user_id, :user_input))
  end

  private
 
  def line_client
    @line_client ||= Line::Bot::Client.new { |config|
      config.channel_secret = ENV["LINE_CHANNEL_SECRET"]
      config.channel_token = ENV["LINE_CHANNEL_TOKEN"]
    }
  end
end
