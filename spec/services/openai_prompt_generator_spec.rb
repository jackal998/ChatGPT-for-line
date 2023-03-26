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
