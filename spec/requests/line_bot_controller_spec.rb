require "rails_helper"

RSpec.describe "LineBotController", type: :request do
  describe "POST #callback" do
    let(:line_message_parser) { instance_double("LineMessage::Parser", {parse: line_user_info}) }
    let(:line_user_info) { {user_id: "123", user_input: "Hi", reply_token: "456"} }

    before do
      allow(LineMessage::Parser).to receive(:new).with(instance_of(ActionDispatch::Request)).and_return(line_message_parser)
    end

    it "returns http success" do
      post "/callback", params: {key: "value"} # TODO: replace with the actual request parameters

      expect(response).to have_http_status(:success)
    end

    it "creates a new job to get messages from openai send a message to the user via LINE API" do
      post "/callback", params: {key: "value"} # TODO: replace with the actual request parameters

      expect(OpenaiResponseJob).to have_enqueued_sidekiq_job(line_user_info)
    end
  end
end
