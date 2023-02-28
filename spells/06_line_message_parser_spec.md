好的，以下是 LineMessageParser 的測試範例及相關設定：

接下來是 LineMessageParser 的測試範例：

```ruby
require 'rails_helper'

RSpec.describe LineMessageParser, type: :service do
  let(:client) { double('line_client') }
  let(:parser) { LineMessageParser.new(client) }
  let(:user_id) { 'U1234567890abcdef1234567890abcdef' }
  let(:user_input) { 'Hello, world!' }
  let(:reply_token) { 'R1234567890abcdef1234567890abcdef' }

  describe '#parse' do
    context 'with valid signature and text message' do
      let(:body) do
        {
          events: [
            {
              type: 'message',
              replyToken: reply_token,
              source: { userId: user_id },
              message: { type: 'text', text: user_input }
            }
          ]
        }.to_json
      end
      let(:signature) { 'valid_signature' }

      before do
        allow(client).to receive(:validate_signature).and_return(true)
        allow(client).to receive(:parse_events_from).and_return([Line::Bot::Event::Message.new(body: body)])
      end

      it 'returns a hash of user id, user input and reply token' do
        result = parser.parse(double('request', body: double('body', read: body), env: { 'HTTP_X_LINE_SIGNATURE' => signature }))
        expect(result).to eq({ user_id: user_id, user_input: user_input, reply_token: reply_token })
      end
    end

    context 'with invalid signature' do
      let(:body) { '' }
      let(:signature) { 'invalid_signature' }

      before do
        allow(client).to receive(:validate_signature).and_return(false)
      end

      it 'raises an error' do
        expect { parser.parse(double('request', body: double('body', read: body), env: { 'HTTP_X_LINE_SIGNATURE' => signature })) }.to raise_error('Invalid signature')
      end
    end

    context 'with non-text message' do
      let(:body) do
        {
          events: [
            {
              type: 'message',
              replyToken: reply_token,
              source: { userId: user_id },
              message: { type: 'image', id: 'image_id' }
            }
          ]
        }.to_json
      end
      let(:signature) { 'valid_signature' }

      before do
        allow(client).to receive(:validate_signature).and_return(true)
        allow(client).to receive(:parse_events_from).and_return([Line::Bot::Event::Message.new(body: body)])
      end

      it 'raises an error' do
        expect { parser.parse(double('request', body: double('body',
```

Prompt:
繼續，你已經寫完一半了!
require 'rails_helper'

RSpec.describe LineMessageParser, type: :service do
  let(:client) { double('line_client') }
  let(:parser) { LineMessageParser.new(client) }
  let(:user_id) { 'U1234567890abcdef1234567890abcdef' }
  let(:user_input) { 'Hello, world!' }
  let(:reply_token) { 'R1234567890abcdef1234567890abcdef' }

  describe '#parse' do
    context 'with valid signature and text message' do
      let(:body) do
        {
          events: [
            {
              type: 'message',
              replyToken: reply_token,
              source: { userId: user_id },
              message: { type: 'text', text: user_input }
            }
          ]
        }.to_json
      end
      let(:signature) { 'valid_signature' }

      before do
        allow(client).to receive(:validate_signature).and_return(true)
        allow(client).to receive(:parse_events_from).and_return([Line::Bot::Event::Message.new(body: body)])
      end

      it 'returns a hash of user id, user input and reply token' do
        result = parser.parse(double('request', body: double('body', read: body), env: { 'HTTP_X_LINE_SIGNATURE' => signature }))
        expect(result).to eq({ user_id: user_id, user_input: user_input, reply_token: reply_token })
      end
    end

    context 'with invalid signature' do
      let(:body) { '' }
      let(:signature) { 'invalid_signature' }

      before do
        allow(client).to receive(:validate_signature).and_return(false)
      end

      it 'raises an error' do
        expect { parser.parse(double('request', body: double('body', read: body), env: { 'HTTP_X_LINE_SIGNATURE' => signature })) }.to raise_error('Invalid signature')
      end
    end

    context 'with non-text message' do
      let(:body) do
        {
          events: [
            {
              type: 'message',
              replyToken: reply_token,
              source: { userId: user_id },
              message: { type: 'image', id: 'image_id' }
            }
          ]
        }.to_json
      end
      let(:signature) { 'valid_signature' }

      before do
        allow(client).to receive(:validate_signature).and_return(true)
        allow(client).to receive(:parse_events_from).and_return([Line::Bot::Event::Message.new(body: body)])
      end

      it 'raises an error' do
        expect { parser.parse(double('request', body: double('body',

ChatGPT:
抱歉，之前我似乎因為字數限制被中斷了，以下是 LineMessageParser 的 RSpec 測試示範：

```ruby
require 'rails_helper'

RSpec.describe LineMessageParser, type: :service do
  let(:client) { double('line_client') }
  let(:parser) { LineMessageParser.new(client) }
  let(:user_id) { 'U1234567890abcdef1234567890abcdef' }
  let(:user_input) { 'Hello, world!' }
  let(:reply_token) { 'R1234567890abcdef1234567890abcdef' }

  describe '#parse' do
    context 'with valid signature and text message' do
      let(:body) do
        {
          events: [
            {
              type: 'message',
              replyToken: reply_token,
              source: { userId: user_id },
              message: { type: 'text', text: user_input }
            }
          ]
        }.to_json
      end
      let(:signature) { 'valid_signature' }

      before do
        allow(client).to receive(:validate_signature).and_return(true)
        allow(client).to receive(:parse_events_from).and_return([Line::Bot::Event::Message.new(body: body)])
      end

      it 'returns a hash of user id, user input and reply token' do
        result = parser.parse(double('request', body: double('body', read: body), env: { 'HTTP_X_LINE_SIGNATURE' => signature }))
        expect(result).to eq({ user_id: user_id, user_input: user_input, reply_token: reply_token })
      end
    end

    context 'with invalid signature' do
      let(:body) { '' }
      let(:signature) { 'invalid_signature' }

      before do
        allow(client).to receive(:validate_signature).and_return(false)
      end

      it 'raises an error' do
        expect { parser.parse(double('request', body: double('body', read: body), env: { 'HTTP_X_LINE_SIGNATURE' => signature })) }.to raise_error('Invalid signature')
      end
    end

    context 'with non-text message' do
      let(:body) do
        {
          events: [
            {
              type: 'message',
              replyToken: reply_token,
              source: { userId: user_id },
              message: { type: 'image', id: 'image_id' }
            }
          ]
        }.to_json
      end
      let(:signature) { 'valid_signature' }

      before do
        allow(client).to receive(:validate_signature).and_return(true)
        allow(client).to receive(:parse_events_from).and_return([Line::Bot::Event::Message.new(body: body)])
      end

      it 'raises an error' do
        expect { parser.parse(double('request', body: double('body', read: body), env: { 'HTTP_X_LINE_SIGNATURE' => signature })) }.to raise_error('No valid user input found')
      end
    end
  end
end
```
這個 RSpec 測試確保了 LineMessageParser 能夠在以下情況下正確運作：

傳入合法的 signature 和文字訊息時，可以正確解析出 user_id、user_input 和 reply_token。
傳入不合法的 signature 時，會拋出 "Invalid signature" 錯誤。
傳入非文字訊息
