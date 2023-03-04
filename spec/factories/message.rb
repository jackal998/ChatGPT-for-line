FactoryBot.define do
  factory :message do
    user_id { "U1234567890abcdef1234567890abcdef" }
    user_input { "Hello, world!" }
    ai_response { "Hi there!" }
    created_at { Time.current }
  end
end
