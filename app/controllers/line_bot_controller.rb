class LineBotController < ApplicationController
  def callback
    line_user_info = LineMessage::Parser.new(request).parse

    OpenaiResponseJob.perform_async(line_user_info)
  end
end
