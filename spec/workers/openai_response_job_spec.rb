require "rails_helper"

RSpec.describe OpenaiResponseJob, type: :job do
  describe "#perform" do
    let(:line_user_info) { {"user_id" => "U1234567890abcdef1234567890abcdef", "user_input" => "Hello", "reply_token" => reply_token} }
    let(:messages) { ["Hi there!", "How are you?"] }
    let(:reply_token) { "R1234567890abcdef1234567890abcdef" }
    let(:message_text) { "Some generated text" }
    let(:message_params) { line_user_info.slice("user_id", "user_input").merge(ai_response: message_text) }

    before do
      allow(OpenaiResponseGenerator).to receive(:new).with(messages).and_return(generator)
      allow(LineMessage::Sender).to receive(:new).with(reply_token).and_return(sender)
    end

    let(:sender) { instance_double(LineMessage::Sender) }
    let(:generator) { instance_double(OpenaiResponseGenerator, {execute: message_text}) }

    it "sends the message to the user and creates a Message record" do
      expect(generator).to receive(:execute).and_return(message_text)
      expect(sender).to receive(:send).with(message_text)
      expect(Message).to receive(:create).with(message_params)

      subject.perform(line_user_info, messages)
    end
  end
end
