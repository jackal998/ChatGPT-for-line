Prompt:
My updated class and old spec file:
```ruby
class OpenaiPromptGenerator
  TOKENS_LIMIT = 3800

  def initialize(user_info)
    @user_info = user_info
  end

  def execute
    total_tokens = 0

    user_messages_with_tokens = Message
      .where(user_id: @user_info[:user_id])
      .where("created_at >= ?", 3.days.ago)
      .order("created_at DESC")
      .each_with_object([]) do |message, arr|
        break arr if total_tokens + message.content_tokens > TOKENS_LIMIT

        total_tokens += message.content_tokens
        arr << {
          message: {role: message.role, content: message.content},
          content_tokens: message.content_tokens
        }
      end

    {
      messages_with_tokens: user_messages_with_tokens.reverse << {
        message: {role: "user", content: @user_info[:user_input]},
        content_tokens: nil
      },
      total_tokens: total_tokens
    }
  end

  def trim_messages(prompt, response)
    latest_content_tokens = response[:prompt_tokens] - prompt[:total_tokens]

    trimed_tokens = 0

    trimed_messages_with_tokens = prompt[:messages_with_tokens].filter_map do |message_with_token|
      trimed_tokens += message_with_token[:content_tokens]
      next if trimed_tokens < latest_content_tokens

      {message: message_with_token[:message], content_tokens: message_with_token[:content_tokens]}
    end

    {
      messages_with_tokens: trimed_messages_with_tokens,
      total_tokens: response[:prompt_tokens] - trimed_tokens
    }
  end
end
```

and old rspec:
```ruby
require "rails_helper"

RSpec.describe OpenaiPromptGenerator, type: :service do
  describe "#execute" do
    let(:user_id) { "U1234567890abcdef1234567890abcdef" }
    let(:user_input) { "Hello, world!" }

    subject { OpenaiPromptGenerator.new(user_id, user_input).execute }

    let!(:older_message) do
      Message.create!(user_id: user_id, role: "assistant", content: "Hi there!", created_at: 4.days.ago)
    end
    let!(:recent_message) do
      Message.create!(user_id: user_id, role: "assistant", content: "How can I help you?", created_at: 2.days.ago)
    end

    it "returns expected array including recent messages" do
      expected_messages = [
        {"role" => "assistant", "content" => recent_message.content},
        {"role" => "user", "content" => user_input}
      ]

      expect(subject).to match_array(expected_messages)
    end
  end
end
```

could you please update the spec file to match the current logic?

ChatGPT:
Sure, here's an updated spec file that matches the current logic:

```ruby
require "rails_helper"

RSpec.describe OpenaiPromptGenerator, type: :service do
  describe "#execute" do
    let(:user_info) { { user_id: "U1234567890abcdef1234567890abcdef", user_input: "Hello, world!" } }

    subject { OpenaiPromptGenerator.new(user_info).execute }

    let!(:older_message) do
      Message.create!(user_id: user_info[:user_id], role: "assistant", content: "Hi there!", created_at: 4.days.ago)
    end
    let!(:recent_message) do
      Message.create!(user_id: user_info[:user_id], role: "assistant", content: "How can I help you?", created_at: 2.days.ago)
    end
    let!(:user_message) do
      Message.create!(user_id: user_info[:user_id], role: "user", content: user_info[:user_input], created_at: Time.zone.now)
    end

    it "returns expected array including recent messages" do
      expected_messages = [
        { "message" => { "role" => "assistant", "content" => recent_message.content }, "content_tokens" => recent_message.content_tokens },
        { "message" => { "role" => "user", "content" => user_info[:user_input] }, "content_tokens" => nil }
      ]

      expect(subject[:messages_with_tokens]).to eq(expected_messages)
    end

    it "returns total tokens" do
      total_tokens = older_message.content_tokens + recent_message.content_tokens + user_message.content_tokens
      expect(subject[:total_tokens]).to eq(total_tokens)
    end
  end

  describe "#trim_messages" do
    let(:prompt) do
      {
        messages_with_tokens: [
          { message: { role: "assistant", content: "Hi there!" }, content_tokens: 10 },
          { message: { role: "assistant", content: "How can I help you?" }, content_tokens: 20 },
          { message: { role: "user", content: "Hello, world!" }, content_tokens: nil }
        ],
        total_tokens: 30
      }
    end

    let(:response) { { prompt_tokens: 50 } }

    subject { OpenaiPromptGenerator.new(nil).trim_messages(prompt, response) }

    it "trims messages based on prompt tokens and returns them with total tokens" do
      expected_messages = [
        { message: { role: "assistant", content: "How can I help you?" }, content_tokens: 20 },
        { message: { role: "user", content: "Hello, world!" }, content_tokens: nil }
      ]

      expect(subject[:messages_with_tokens]).to eq(expected_messages)
      expect(subject[:total_tokens]).to eq(20)
    end
  end
end
```

Let me know if you have any questions!
