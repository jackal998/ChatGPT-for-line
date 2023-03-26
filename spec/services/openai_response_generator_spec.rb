require "rails_helper"

RSpec.describe OpenaiResponseGenerator, type: :service do
  describe "#execute" do
    let(:api_response) { JSON.parse(file_fixture("openai_response.json").read) }

    subject { described_class.new(messages).execute }

    let(:messages) { [{"role" => "user", "content" => "Hello, how are you?"}] }

    before do
      expect_any_instance_of(OpenAI::Client).to receive(:chat).with(
        parameters: {
          model: "gpt-3.5-turbo",
          messages: messages
        }
      ).and_return(api_response)
    end

    it "calls the OpenAI API with the given messages and parse the AI response text" do
      expect(subject).to eq("Hello there, how may I assist you today?")
    end
  end
end
