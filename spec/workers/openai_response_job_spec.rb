require "rails_helper"

RSpec.describe OpenaiResponseJob, type: :job do
  describe "#perform" do
    let(:user_id) { "U1234567890abcdef1234567890abcdef" }
    let(:reply_token) { "R1234567890abcdef1234567890abcdef" }
    let(:line_user_info) { {user_id: user_id, user_input: "Hello", reply_token: reply_token} }
    let(:prompt_generator) { instance_double(OpenaiPromptGenerator, execute: prompt) }
    let(:prompt) do
      {
        messages_with_tokens: [
          {message: {role: "assistant", content: "Hi there!"}, content_tokens: 10},
          {message: {role: "assistant", content: "How can I help you?"}, content_tokens: 20},
          {message: {role: "user", content: "Hello, world!"}, content_tokens: nil}
        ],
        total_tokens: 30
      }
    end
    let(:response) { {message: "Some generated text", content_tokens: 40, prompt_tokens: 10} }
    let(:sender) { instance_double(LineMessage::Sender) }

    before do
      allow(OpenaiPromptGenerator).to receive(:new).with(line_user_info).and_return(prompt_generator)
      allow(OpenaiResponseGenerator).to receive(:new).with(prompt[:messages_with_tokens].pluck(:message)).and_return(instance_double(OpenaiResponseGenerator, execute: response))
      allow(LineMessage::Sender).to receive(:new).with(reply_token).and_return(sender)
      allow(sender).to receive(:send)
      allow(Message).to receive(:insert_all)
    end

    it "sends the message to the user and creates Message records" do
      expect(sender).to receive(:send).with(response[:message])
      expect(Message).to receive(:insert_all).with([
        {role: "user", content: line_user_info[:user_input], user_id: user_id, content_tokens: response[:prompt_tokens] - prompt[:total_tokens]},
        {role: "assistant", content: response[:message], user_id: user_id, content_tokens: response[:content_tokens]}
      ])

      subject.perform(line_user_info)
    end

    context "when context_length_exceeded error occurs" do
      let(:response) { {error: "context_length_exceeded"} }
      let(:trimmed_prompt) do
        {
          messages_with_tokens: [
            {message: {role: "assistant", content: "How can I help you?"}, content_tokens: 20},
            {message: {role: "user", content: "Hello, world!"}, content_tokens: nil}
          ],
          total_tokens: 30
        }
      end
      let(:second_response) { {message: "Some generated text", content_tokens: 30, prompt_tokens: 10} }

      before do
        allow(OpenaiResponseGenerator).to receive(:new).with(trimmed_prompt[:messages_with_tokens].pluck(:message)).and_return(instance_double(OpenaiResponseGenerator, execute: second_response))
        allow(prompt_generator).to receive(:trim_messages).with(prompt, response).and_return(trimmed_prompt)
      end

      it "handles the error and retries with trimmed prompt" do
        expect(sender).to receive(:send).with(second_response[:message])
        expect(Message).to receive(:insert_all).with([
          {role: "user", content: line_user_info[:user_input], user_id: user_id, content_tokens: second_response[:prompt_tokens] - trimmed_prompt[:total_tokens]},
          {role: "assistant", content: second_response[:message], user_id: user_id, content_tokens: second_response[:content_tokens]}
        ])

        subject.perform(line_user_info)
      end
    end
  end
end
