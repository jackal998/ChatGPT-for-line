require "rails_helper"

RSpec.describe LineMessageSender, type: :service do
  describe "#send" do
    let(:message_text) { "Hello, world!" }
    let(:message) { {type: "text", text: message_text} }
    let(:client) { double("line_client") }
    let(:reply_token) { "R1234567890abcdef1234567890abcdef" }

    subject { LineMessageSender.new(client, reply_token).send(message_text) }

    it "sends the message to the client" do
      expect(client).to receive(:reply_message).with(reply_token, message)

      subject
    end
  end
end
