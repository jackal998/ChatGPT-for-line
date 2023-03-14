OpenAI.configure do |config|
  config.access_token = Rails.env.test? ? "" : Rails.application.credentials.openai[:access_token]
end
