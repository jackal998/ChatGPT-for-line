require "rails_helper"

RSpec.describe "LineBotController", type: :request do
  describe "POST #callback" do
    let(:line_client) { instance_double(Line::Bot::Client) }
    let(:parsed_line_message) { { user_id: "123", user_input: "Hi", reply_token: "456" } }

    before do
      allow(LineMessageParser).to receive_message_chain(:new, :parse).and_return(parsed_line_message)
      allow(OpenaiPromptGenerator).to receive_message_chain(:new, :execute).and_return("prompt")
      allow(OpenaiResponseGenerator).to receive_message_chain(:new, :execute).and_return("response")
      allow(LineMessageSender).to receive_message_chain(:new, :send)
      post "/callback", params: { "key": "value" } # replace with the actual request parameters
    end

    it "returns http success" do
      expect(response).to have_http_status(:success)
    end

    it "parses the line message" do
      expect(LineMessageParser).to have_received(:new).with(instance_of(Line::Bot::Client)).once
      expect(LineMessageParser.new(line_client)).to have_received(:parse).with(instance_of(ActionDispatch::Request)).once
    end

    it "generates an OpenAI prompt and response" do
      expect(OpenaiPromptGenerator).to have_received(:new).with("123", "Hi").once
      expect(OpenaiPromptGenerator.new("123", "Hi")).to have_received(:execute).once

      expect(OpenaiResponseGenerator).to have_received(:new).with("prompt").once
      expect(OpenaiResponseGenerator.new("prompt")).to have_received(:execute).once
    end

    it "sends the response back to Line" do
      expect(LineMessageSender).to have_received(:new).with(instance_of(Line::Bot::Client), "456").once
      expect(LineMessageSender.new(line_client, "456")).to have_received(:send).with("response").once
    end

    it "saves the message to the database" do
      expect(Message.count).to eq(1)
      expect(Message.last).to have_attributes(
        user_id: "123",
        user_input: "Hi",
        ai_response: "response"
      )
    end
  end
end
