Prompt:
class LineMessageSender
  def initialize(client, replyToken)
    @client = client
    @replyToken = replyToken
  end

  def send(message_text)
    message = {
      type: "text",
      text: message_text
    }

    @client.reply_message(@replyToken, message)
  end
end

ChatGPT:
這個 LineMessageSender 類別負責將訊息回傳給 LINE 平台，讓 LINE 平台可以把訊息轉發給使用者。要寫測試時，需要模擬 @client 物件的行為，並檢查 @client.reply_message 方法有沒有被正確地呼叫。

下面是 LineMessageSender 的測試範例：

```ruby
require 'rails_helper'

RSpec.describe LineMessageSender, type: :service do
  let(:client) { double('line_client') }
  let(:reply_token) { 'R1234567890abcdef1234567890abcdef' }

  describe '#send' do
    let(:message_text) { 'Hello, world!' }
    let(:message) { { type: 'text', text: message_text } }

    it 'sends the message to the client' do
      expect(client).to receive(:reply_message).with(reply_token, message)
      sender = LineMessageSender.new(client, reply_token)
      sender.send(message_text)
    end
  end
end
```
需要注意的是，在測試中我們使用 double 方法建立了一個假的 line_client 物件，這是為了避免真的和 LINE 平台互動，並且可以控制假的物件的行為，讓它在測試時遵守我們所預期的行為。
