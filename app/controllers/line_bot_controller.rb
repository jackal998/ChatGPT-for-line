class LineBotController < ApplicationController
  def callback
    line_user_info = LineMessage::Parser.new(request).parse

    messages = OpenaiPromptGenerator.new(*line_user_info.values_at(:user_id, :user_input)).execute

    OpenaiResponseJob.perform_async(line_user_info, messages)
  end
end
