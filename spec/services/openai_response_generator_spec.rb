require "rails_helper"

RSpec.describe OpenaiResponseGenerator, type: :service do
  describe "#execute" do
    let(:api_response) { JSON.parse(file_fixture("openai_response.json").read) }

    subject { described_class.new(messages).execute }

    context "when the response is successful" do
      let(:messages) { [{"role" => "user", "content" => "Hello, how are you?"}] }

      before do
        expect_any_instance_of(OpenAI::Client).to receive(:chat).with(
          parameters: {
            model: "gpt-3.5-turbo",
            messages: messages
          }
        ).and_return(api_response)
      end

      it "returns the AI response text and usage tokens" do
        expect(subject[:message]).to eq("Hello there, how may I assist you today?")
        expect(subject[:prompt_tokens]).to eq(api_response["usage"]["prompt_tokens"])
        expect(subject[:content_tokens]).to eq(api_response["usage"]["completion_tokens"])
      end
    end

    context "when the API response has a context_length_exceeded error" do
      let(:messages) { [{"role" => "user", "content" => "Hello, how are you?"}] }
      let(:error_message) { "Context length exceeded with 1000 tokens, max allowed: #{max_tokens}" }
      let(:max_tokens) { 2048 }

      before do
        expect_any_instance_of(OpenAI::Client).to receive(:chat).and_return(
          "error" => {
            "code" => "context_length_exceeded",
            "message" => error_message
          }
        )
      end

      it "returns an error and the number of prompt tokens used" do
        expect(subject[:error]).to eq("context_length_exceeded")
        expect(subject[:prompt_tokens]).to eq(max_tokens.to_s)
      end
    end

    context "when the API response has a length error" do
      let(:messages) { [{"role" => "user", "content" => "Hello, how are you?"}] }

      before do
        expect_any_instance_of(OpenAI::Client).to receive(:chat).and_return(
          "choices" => [
            {
              "finish_reason" => "length"
            }
          ],
          "usage" => {
            "prompt_tokens" => 75_000
          }
        )
      end

      it "returns an error and the number of prompt tokens used" do
        expect(subject[:error]).to eq("context_length_exceeded")
        expect(subject[:prompt_tokens]).to eq(75_000)
      end
    end

    context "when the API response does not have a content field" do
      let(:messages) { [{"role" => "user", "content" => "Hello, how are you?"}] }

      before do
        expect_any_instance_of(OpenAI::Client).to receive(:chat).and_return(
          "choices" => [
            {
              "message" => {}
            }
          ]
        )
      end

      it "raises an error" do
        expect { subject }.to raise_error(RuntimeError)
      end
    end
  end
end
