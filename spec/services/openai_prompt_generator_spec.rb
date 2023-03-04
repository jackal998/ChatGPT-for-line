require "rails_helper"

RSpec.describe OpenaiPromptGenerator, type: :service do
  describe "#execute" do
    let(:user_id) { "U1234567890abcdef1234567890abcdef" }
    let(:user_input) { "Hello, world!" }

    subject { OpenaiPromptGenerator.new(user_id, user_input).execute }

    shared_examples "current user input under a fixed lenth limit" do
      it "returns a string with current user input under a fixed lenth limit" do
        expect(subject.length).to be <= described_class::MAX_TOKENS
        is_expected.to include("user_input:#{user_input}")
      end
    end

    context "with recent conversations" do
      def create_messages(message_age:, user_id: nil)
        create_list(:message, rand(10), user_id: user_id, user_input: "#{message_age}.minutes.ago", created_at: message_age.minutes.ago)
      end

      let!(:user_messages_31_minutes_ago) { create_messages(user_id: user_id, message_age: 31) }
      let!(:user_messages_29_minutes_ago) { create_messages(user_id: user_id, message_age: 29) }
      let!(:other_messages_28_minutes_ago) { create_messages(message_age: 28) }

      it "returns a string including recent conversations" do
        recent_conversations = user_messages_29_minutes_ago.map do |message|
          "user_input:#{message.user_input} ai_response:#{message.ai_response}"
        end.join(" ")

        is_expected.to include(recent_conversations)
      end

      include_examples "current user input under a fixed lenth limit"
    end

    context "without recent conversations" do
      it "returns a string without recent conversations" do
        is_expected.not_to include("ai_response:")
      end

      include_examples "current user input under a fixed lenth limit"
    end
  end
end
