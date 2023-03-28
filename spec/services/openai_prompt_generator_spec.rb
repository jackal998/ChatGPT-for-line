require "rails_helper"

RSpec.describe OpenaiPromptGenerator, type: :service do
  describe "#execute" do
    let(:user_info) { {user_id: "U1234567890abcdef1234567890abcdef", user_input: "Hello, world!"} }

    subject { OpenaiPromptGenerator.new(user_info).execute }

    let!(:older_message) do
      Message.create(user_id: user_info[:user_id], role: "assistant", content: "Hi there!", content_tokens: 15, created_at: 4.days.ago)
    end
    let!(:recent_message) do
      Message.create(user_id: user_info[:user_id], role: "assistant", content: "How can I help you?", content_tokens: 25, created_at: 2.days.ago)
    end

    it "returns expected array including recent messages" do
      expected_messages = [
        {message: {role: "assistant", content: recent_message.content}, content_tokens: recent_message.content_tokens},
        {message: {role: "user", content: user_info[:user_input]}, content_tokens: nil}
      ]

      expect(subject[:messages_with_tokens]).to eq(expected_messages)
    end

    it "returns total tokens from db records in the past 3 days" do
      expect(subject[:total_tokens]).to eq(recent_message.content_tokens)
    end
  end

  describe "#trim_messages" do
    let(:user_info) { {user_id: "U1234567890abcdef1234567890abcdef", user_input: "Hello, world!"} }

    subject { OpenaiPromptGenerator.new(user_info).trim_messages(prompt, response) }

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

    let(:response) { {prompt_tokens: 50} }

    it "trims messages based on prompt tokens and returns them with total tokens" do
      expected_messages = [
        {message: {role: "assistant", content: "How can I help you?"}, content_tokens: 20},
        {message: {role: "user", content: "Hello, world!"}, content_tokens: nil}
      ]

      expect(subject[:messages_with_tokens]).to eq(expected_messages)
      expect(subject[:total_tokens]).to eq(20)
    end
  end
end
