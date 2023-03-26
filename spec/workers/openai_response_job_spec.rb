require "rails_helper"

RSpec.describe OpenaiResponseJob, type: :job do
  describe "#perform" do
    let(:user_id) { "U1234567890abcdef1234567890abcdef" }
    let(:line_user_info) { {"user_id" => user_id, "user_input" => "Hello", "reply_token" => reply_token} }
    let(:messages) do
      [
        {"role" => "assistant", "content" => "Hi there!"},
        {"role" => "user", "content" => "Hello, how are you?"}
      ]
    end
    let(:generator) { instance_double(OpenaiResponseGenerator, {execute: message_text}) }
    let(:message_text) { "Some generated text" }

    let(:reply_token) { "R1234567890abcdef1234567890abcdef" }
    let(:sender) { instance_double(LineMessage::Sender) }

    before do
      allow(OpenaiResponseGenerator).to receive(:new).with(messages).and_return(generator)
      allow(LineMessage::Sender).to receive(:new).with(reply_token).and_return(sender)
    end

    it "sends the message to the user and creates Message records" do
      expect(generator).to receive(:execute).and_return(message_text)
      expect(sender).to receive(:send).with(message_text)

      expect { subject.perform(line_user_info, messages) }.to change { Message.where(user_id: user_id).count }.by(2)
    end
  end
end
