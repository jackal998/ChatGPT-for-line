require "rails_helper"

RSpec.describe LineMessage::Parser, type: :service do
  describe "#parse" do
    subject { parser.parse }

    before do
      allow(parser).to receive(:client).and_return(client)
      allow(client).to receive(:parse_events_from).and_return([Line::Bot::Event::Message.new(event)])
    end

    let(:request) { double("request", body: double("body", read: event), env: {"HTTP_X_LINE_SIGNATURE" => signature}) }
    let(:client) { double("line_client") }
    let(:parser) { described_class.new(request) }

    let(:user_id) { "U1234567890abcdef1234567890abcdef" }
    let(:user_input) { "Hello, world!" }
    let(:reply_token) { "R1234567890abcdef1234567890abcdef" }
    let(:message) { {"type" => "text", "text" => user_input} }
    let(:event) do
      {
        "type" => "message",
        "replyToken" => reply_token,
        "source" => {"userId" => user_id},
        "message" => message
      }
    end

    context "with invalid signature" do
      let(:signature) { "invalid_signature" }

      before do
        allow(client).to receive(:validate_signature).and_return(false)
      end

      it "raises an error" do
        expect { subject }.to raise_error("Invalid signature")
      end
    end

    context "with valid signature" do
      let(:signature) { "valid_signature" }

      before do
        allow(client).to receive(:validate_signature).and_return(true)
      end

      context "with text message" do
        it "returns a hash of user id, user input and reply token" do
          is_expected.to eq({user_id: user_id, user_input: user_input, reply_token: reply_token})
        end
      end

      context "with non-text message" do
        let(:message) { {"type" => "image", "id" => "image_id"} }

        it "raises an error" do
          expect { subject }.to raise_error("No valid user input found")
        end
      end
    end
  end
end
