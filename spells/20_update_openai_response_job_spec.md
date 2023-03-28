Prompt:
My updated class and old spec file:
```ruby
class OpenaiResponseJob
  include Sidekiq::Worker

  def perform(user_info)
    user_info.deep_symbolize_keys!
    prompt_generator = OpenaiPromptGenerator.new(user_info)

    prompt = prompt_generator.execute
    response = get_response(prompt)

    if response[:error] == "context_length_exceeded"
      prompt = prompt_generator.trim_messages(prompt, response)
      response = get_response(prompt)
    end

    LineMessage::Sender.new(user_info[:reply_token]).send(response[:message])

    Message.insert_all([
      {role: "user", content: user_info[:user_input], user_id: user_info[:user_id], content_tokens: response[:prompt_tokens] - prompt[:total_tokens]},
      {role: "assistant", content: response[:message], user_id: user_info[:user_id], content_tokens: response[:content_tokens]}
    ])
  end

  private

  def get_response(prompt)
    OpenaiResponseGenerator.new(prompt[:messages_with_tokens].pluck(:message)).execute
  end
end
```
and the `prompt` from prompt_generator.execute also changed to a hash:
```ruby
      {
        messages_with_tokens: [
          {message: {role: "assistant", content: "Hi there!"}, content_tokens: 10},
          {message: {role: "assistant", content: "How can I help you?"}, content_tokens: 20},
          {message: {role: "user", content: "Hello, world!"}, content_tokens: nil}
        ],
        total_tokens: 30
      }
```

and here you are the old rspec:
```ruby
require "rails_helper"

RSpec.describe OpenaiResponseJob, type: :job do
  describe "#perform" do
    let(:user_id) { "U1234567890abcdef1234567890abcdef" }
    let(:line_user_info) { {"user_id" => user_id, "user_input" => "Hello", "reply_token" => reply_token} }
    let(:messages) do
      [
        {"role" => "assistant", "content" => "Hi there!"},
        {"role" => "user", "content" => "Hello, how are you?"}
      ]
    end
    let(:generator) { instance_double(OpenaiResponseGenerator, {execute: message_text}) }
    let(:message_text) { "Some generated text" }

    let(:reply_token) { "R1234567890abcdef1234567890abcdef" }
    let(:sender) { instance_double(LineMessage::Sender) }

    before do
      allow(OpenaiResponseGenerator).to receive(:new).with(messages).and_return(generator)
      allow(LineMessage::Sender).to receive(:new).with(reply_token).and_return(sender)
    end

    it "sends the message to the user and creates Message records" do
      expect(generator).to receive(:execute).and_return(message_text)
      expect(sender).to receive(:send).with(message_text)

      expect { subject.perform(line_user_info, messages) }.to change { Message.where(user_id: user_id).count }.by(2)
    end
  end
end
```

could you please update the spec file to match the current logic?

ChatGPT:
Sure! Here's the updated spec file:

```ruby
require "rails_helper"

RSpec.describe OpenaiResponseJob, type: :job do
  describe "#perform" do
    let(:user_id) { "U1234567890abcdef1234567890abcdef" }
    let(:reply_token) { "R1234567890abcdef1234567890abcdef" }
    let(:line_user_info) { { user_id: user_id, user_input: "Hello", reply_token: reply_token } }
    let(:prompt) do
      {
        messages_with_tokens: [
          { message: { role: "assistant", content: "Hi there!" }, content_tokens: 10 },
          { message: { role: "assistant", content: "How can I help you?" }, content_tokens: 20 },
          { message: { role: "user", content: "Hello, world!" }, content_tokens: nil }
        ],
        total_tokens: 30
      }
    end
    let(:response) { { message: "Some generated text", content_tokens: 40, prompt_tokens: 10 } }
    let(:sender) { instance_double(LineMessage::Sender) }

    before do
      allow(OpenaiPromptGenerator).to receive(:new).with(line_user_info).and_return(instance_double(OpenaiPromptGenerator, execute: prompt))
      allow(OpenaiResponseGenerator).to receive(:new).with(prompt[:messages_with_tokens].pluck(:message)).and_return(instance_double(OpenaiResponseGenerator, execute: response))
      allow(LineMessage::Sender).to receive(:new).with(reply_token).and_return(sender)
      allow(sender).to receive(:send)
      allow(Message).to receive(:insert_all)
    end

    it "sends the message to the user and creates Message records" do
      expect(sender).to receive(:send).with(response[:message])
      expect(Message).to receive(:insert_all).with([
        { role: "user", content: line_user_info[:user_input], user_id: user_id, content_tokens: response[:prompt_tokens] - prompt[:total_tokens] },
        { role: "assistant", content: response[:message], user_id: user_id, content_tokens: response[:content_tokens] }
      ])

      subject.perform(line_user_info)
    end

    context "when context_length_exceeded error occurs" do
      let(:response) { { error: "context_length_exceeded" } }
      let(:trimmed_prompt) do
        {
          messages_with_tokens: [
            { message: { role: "assistant", content: "Hi there!" }, content_tokens: 10 },
            { message: { role: "assistant", content: "How can I help you?" }, content_tokens: 20 },
            { message: { role: "user", content: "Hello, world!" }, content_tokens: nil }
          ],
          total_tokens: 20
        }
      end
      let(:second_response) { { message: "Some generated text", content_tokens: 30, prompt_tokens: 10 } }

      before do
        allow(OpenaiResponseGenerator).to receive(:new).with(trimmed_prompt[:messages_with_tokens].pluck(:message)).and_return(instance_double(OpenaiResponseGenerator, execute: second_response))
        allow_any_instance_of(OpenaiPromptGenerator).to receive(:trim_messages).and_return(trimmed_prompt)
      end

      it "handles the error and retries with trimmed prompt" do
        expect(sender).to receive(:send).with(second_response[:message])
        expect(Message).to receive(:insert_all).with([
          { role: "user", content: line_user_info[:user_input], user_id: user_id, content_tokens: second_response[:prompt_tokens] - trimmed_prompt[:total_tokens] },
          { role: "assistant", content: second_response[:message], user_id: user_id, content_tokens: second_response[:content_tokens] }
        ])

        subject.perform(line_user_info)
      end
    end
  end
end
```

This spec file now includes tests for the case where the `context_length_exceeded` error occurs and the prompt needs to be trimmed.
