module LineMessage
  class Base
    private

    def client
      @_client ||= Line::Bot::Client.new { |config|
        config.channel_secret = Rails.application.credentials.line_channel[:secret]
        config.channel_token = Rails.application.credentials.line_channel[:token]
      }
    end
  end
end
