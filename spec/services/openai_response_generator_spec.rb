require "rails_helper"

RSpec.describe OpenaiResponseGenerator, type: :service do
  describe "#execute" do
    subject { described_class.new(prompt).execute }

    let(:prompt) { "Hello, world!" }

    before do
      expect_any_instance_of(OpenAI::Client).to receive(:completions).with(
        parameters: {
          model: "text-davinci-003",
          prompt: prompt,
          max_tokens: 500
        }
      ).and_return(api_response)
    end

    context "when response includes the ai_response prefix" do
      let(:api_response) do
        {
          "choices" => [
            {
              "text" => "ai_response:Here is the AI response."
            }
          ]
        }
      end

      it "calls the OpenAI API with the given prompt and returns the AI response text" do
        expect(subject).to eq("Here is the AI response.")
      end
    end

    context "when response does not include the ai_response prefix" do
      let(:api_response) do
        {
          "choices" => [
            {
              "text" => "Here is the AI response."
            }
          ]
        }
      end

      it "calls the OpenAI API with the given prompt and returns the AI response text" do
        expect(subject).to eq("Here is the AI response.")
      end
    end
  end
end
