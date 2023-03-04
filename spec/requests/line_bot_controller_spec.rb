require "rails_helper"

RSpec.describe "LineBotController", type: :request do
  describe "POST #callback" do
    let(:line_message_parser) { instance_double("LineMessage::Parser", {parse: line_user_info}) }
    let(:line_user_info) { {user_id: "123", user_input: "Hi", reply_token: "456"} }

    let(:openai_prompt_generator) { instance_double("OpenaiPromptGenerator", {execute: messages}) }
    let(:messages) { ["message1", "message2"] }

    before do
      allow(LineMessage::Parser).to receive(:new).with(instance_of(ActionDispatch::Request)).and_return(line_message_parser)
      allow(OpenaiPromptGenerator).to receive(:new).with(*line_user_info.values_at(:user_id, :user_input)).and_return(openai_prompt_generator)

      post "/callback", params: {key: "value"} # TODO: replace with the actual request parameters
    end

    it "returns http success" do
      expect(response).to have_http_status(:success)
    end

    it "creates a new job to get messages from openai send a message to the user via LINE API" do
      expect(line_message_parser).to have_received(:parse).once
      expect(openai_prompt_generator).to have_received(:execute).once

      expect(OpenaiResponseJob).to have_enqueued_sidekiq_job(line_user_info, messages)
    end
  end
end
