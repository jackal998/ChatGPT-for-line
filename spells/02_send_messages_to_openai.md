Prompt:
我要新增一個功能，將line接收到的訊息傳到openai api，並等待openai 回傳的訊息之後再回傳給line，請問我應該怎麼修改我的程式?

ChatGPT:
要新增一個功能，將Line接收到的訊息傳送到OpenAI API並等待回應之後再傳送回Line，你可以按照以下步驟進行修改：

在Gemfile中新增 openai gem：

```ruby
gem 'openai'
```
在Rails應用程式中的 config/application.rb 檔案中加入：

```ruby
config.autoload_paths << Rails.root.join('lib')
```
在應用程式根目錄下創建一個名為lib的目錄。在這個目錄下創建一個新的檔案，例如 openai.rb，加入以下程式碼，用於設定你的OpenAI API key：

```ruby
require 'openai'

OpenAI.api_key = ENV['OPENAI_API_KEY']
```
注意替換 ENV['OPENAI_API_KEY'] 為你的OpenAI API key。

在控制器中加入以下程式碼，用於處理訊息並傳送到OpenAI API：

```ruby
require 'openai'

class LineBotController < ApplicationController
  protect_from_forgery except: [:callback]

  def callback
    body = request.body.read
    signature = request.env['HTTP_X_LINE_SIGNATURE']

    unless client.validate_signature(body, signature)
      head :bad_request
      return
    end

    events = client.parse_events_from(body)

    events.each do |event|
      case event
      when Line::Bot::Event::Message
        case event.type
        when Line::Bot::Event::MessageType::Text
          reply_token = event['replyToken']
          text = event.message['text']

          response = OpenAI::Completion.create(
            engine: 'davinci-codex',
            prompt: text,
            max_tokens: 60,
            n: 1,
            stop: ['\n']
          )

          message = {
            type: 'text',
            text: response.choices[0].text
          }

          client.reply_message(reply_token, message)
        end
      end
    end

    head :ok
  end

  private

  def client
    @client ||= Line::Bot::Client.new { |config|
      config.channel_secret = ENV['LINE_CHANNEL_SECRET']
      config.channel_token = ENV['LINE_CHANNEL_TOKEN']
    }
  end
end
```
這個範例程式碼中，當收到一個文字訊息時，將訊息傳送到OpenAI API進行處理，然後把回傳的訊息回傳回Line。

請確保你已經在.env檔案中設定了LINE_CHANNEL_SECRET和LINE_CHANNEL_TOKEN以及OPENAI_API_KEY環境變數。

重新啟動Rails server，並測試Line Bot應用程式，應該可以正確運作。

以上就是你可以遵循的步驟，讓你的Line Bot應用程式

Prompt:
openai這個套件已經三年沒有更新了，可以改用ruby-openai這個套件嗎?

ChatGPT:
是的，你可以改用ruby-openai這個套件來取代openai套件。ruby-openai是一個開源的Ruby程式庫，可用於與OpenAI API進行交互，並且有較活躍的開發者社群維護，因此使用起來應該會更加穩定和可靠。你可以使用以下指令安裝ruby-openai:

```ruby
gem install openai
```
之後你就可以修改你的程式碼，使用ruby-openai套件來與OpenAI API進行交互。

Prompt:
我需要你幫我修改成用ruby-openai這個套件的程式碼

ChatGPT:
好的，以下是一個使用ruby-openai套件的範例程式碼，可以將Line接收到的訊息傳送到OpenAI API，並將回傳的訊息回覆給Line：

```ruby
require 'line/bot'
require 'openai'

class LineBotController < ApplicationController
  protect_from_forgery except: [:callback]

  def callback
    body = request.body.read
    signature = request.env['HTTP_X_LINE_SIGNATURE']
    unless client.validate_signature(body, signature)
      head :bad_request
      return
    end
    events = client.parse_events_from(body)
    events.each do |event|
      case event
      when Line::Bot::Event::Message
        case event.type
        when Line::Bot::Event::MessageType::Text
          text = event.message['text']
          response = OpenAI::Completion.create(engine: "text-davinci-002", prompt: text, max_tokens: 5)
          reply_text = response.choices.first.text
          message = {
            type: 'text',
            text: reply_text
          }
          client.reply_message(event['replyToken'], message)
        end
      end
    end
    head :ok
  end

  private

  def client
    @client ||= Line::Bot::Client.new { |config|
      config.channel_secret = ENV['LINE_CHANNEL_SECRET']
      config.channel_token = ENV['LINE_CHANNEL_TOKEN']
    }
  end
end
```
在這個範例程式碼中，我們使用了ruby-openai套件的Completion.create方法，以傳入Line接收到的文字訊息為prompt，獲取OpenAI API回傳的文字訊息作為回應。注意需要先使用 gem install openai 安裝ruby-openai套件，並確認已在.env檔案中設置了OPENAI_API_KEY變量，否則需要在程式碼中設置。

Prompt:
你的資料庫沒有更新，我剛剛修改了我的controller，讓他可以使用ruby-openai，但是看起來有點不太對，你能幫我重構一下嗎？
class LineBotController < ApplicationController
  def callback
    body = request.body.read
    signature = request.env["HTTP_X_LINE_SIGNATURE"]
    unless client.validate_signature(body, signature)
      head :bad_request
    end
 
    events = client.parse_events_from(body)
 
    events.each do |event|
      case event
      when Line::Bot::Event::Message
        case event.type
        when Line::Bot::Event::MessageType::Text
          reply_token = event["replyToken"]
          text = event.message["text"]

          response = OpenAI::Client.new.completions(
            parameters: {
                model: "text-davinci-003",
                prompt: text,
                max_tokens: 5
            })

          message = {
            type: "text",
            text: response["choices"][0]["text"]
          }
 
          client.reply_message(event["replyToken"], message)
        end
      end
    end
 
    head :ok
  end
 
  private
 
  def client
    @client ||= Line::Bot::Client.new { |config|
      config.channel_secret = ENV["LINE_CHANNEL_SECRET"]
      config.channel_token = ENV["LINE_CHANNEL_TOKEN"]
    }
  end
end

ChatGPT:
好的，讓我來幫您重構一下程式碼，使用 ruby-openai 套件：

```ruby
class LineBotController < ApplicationController
  def callback
    body = request.body.read
    signature = request.env["HTTP_X_LINE_SIGNATURE"]
    unless client.validate_signature(body, signature)
      head :bad_request
    end
 
    events = client.parse_events_from(body)
 
    events.each do |event|
      case event
      when Line::Bot::Event::Message
        case event.type
        when Line::Bot::Event::MessageType::Text
          reply_token = event["replyToken"]
          text = event.message["text"]

          response = OpenAI::Completion.create(
            engine: "davinci",
            prompt: text,
            max_tokens: 5
          )

          message = {
            type: "text",
            text: response.choices[0].text
          }
 
          client.reply_message(reply_token, message)
        end
      end
    end
 
    head :ok
  end
 
  private
 
  def client
    @client ||= Line::Bot::Client.new { |config|
      config.channel_secret = ENV["LINE_CHANNEL_SECRET"]
      config.channel_token = ENV["LINE_CHANNEL_TOKEN"]
    }
  end
end
```
修改的部分有：

利用 OpenAI::Completion.create 來取代 OpenAI::Client.new.completions。
將 response["choices"][0]["text"] 取代為 response.choices[0].text。
這樣修改應該可以讓程式運作了，請您再測試看看是否正常。

Prompt:
您修改的地方是錯的，而這兩個地方正是我研究之後發現這是新版ruby-openai 套件的用法

我想要紀錄line傳進來的訊息以及openai回傳的訊息，應該怎麼修改我的專案?

ChatGPT:
要紀錄line傳進來的訊息以及openai回傳的訊息，可以在處理完OpenAI的回傳訊息之後，新增一個記錄訊息的功能。以下是一個修改過的controller範例，其中加入了將接收到的訊息、OpenAI回傳的訊息、以及回傳給line的訊息都紀錄到資料庫的功能：

```ruby
class LineBotController < ApplicationController
  def callback
    body = request.body.read
    signature = request.env["HTTP_X_LINE_SIGNATURE"]
    unless client.validate_signature(body, signature)
      head :bad_request
    end
 
    events = client.parse_events_from(body)
 
    events.each do |event|
      case event
      when Line::Bot::Event::Message
        case event.type
        when Line::Bot::Event::MessageType::Text
          reply_token = event["replyToken"]
          text = event.message["text"]

          response = OpenAI::Model.new.completions(
            engine: "davinci",
            prompt: text,
            max_tokens: 5
          )

          openai_text = response["choices"][0]["text"]

          # 將訊息紀錄到資料庫
          Message.create(line_text: text, openai_text: openai_text, line_reply: nil)

          message = {
            type: "text",
            text: openai_text
          }

          # 將回應訊息紀錄到資料庫
          Message.last.update(line_reply: openai_text)

          client.reply_message(reply_token, message)

          # 將回應訊息紀錄到資料庫
          Message.last.update(line_reply: message[:text])
        end
      end
    end
 
    head :ok
  end
 
  private
 
  def client
    @client ||= Line::Bot::Client.new { |config|
      config.channel_secret = ENV["LINE_CHANNEL_SECRET"]
      config.channel_token = ENV["LINE_CHANNEL_TOKEN"]
    }
  end
end
```
在以上範例中，我們先將接收到的訊息以及OpenAI回傳的訊息紀錄到資料庫的Message表格中，其中line_text欄位紀錄Line傳來的訊息，openai_text欄位紀錄OpenAI回傳的訊息，line_reply欄位用來紀錄回傳給Line的訊息，一開始設為nil。接著將OpenAI回傳的訊息當做回應訊息回傳給Line，同時也紀錄到Message表格的line_reply欄位中。

Prompt:
兩件事，第一，我認為一個回應週期裡面應該只需要一次Message.create就夠了
第二，我應該如何建立Message這個資料庫?

ChatGPT:
第一件事，您是對的，一個回應週期內只需要建立一次Message紀錄即可。請參考下列修改後的程式碼：

```ruby
class LineBotController < ApplicationController
  def callback
    body = request.body.read
    signature = request.env["HTTP_X_LINE_SIGNATURE"]
    unless client.validate_signature(body, signature)
      head :bad_request
    end
 
    events = client.parse_events_from(body)
 
    events.each do |event|
      case event
      when Line::Bot::Event::Message
        case event.type
        when Line::Bot::Event::MessageType::Text
          reply_token = event["replyToken"]
          text = event.message["text"]

          response = Openai::Completion.create(
            engine: 'text-davinci-002',
            prompt: text,
            max_tokens: 5
          )

          message_text = response.choices[0].text

          # Create a Message record with the user's input and OpenAI's response
          Message.create(user_input: text, ai_response: message_text)

          message = {
            type: "text",
            text: message_text
          }
 
          client.reply_message(event["replyToken"], message)
        end
      end
    end
 
    head :ok
  end
 
  private
 
  def client
    @client ||= Line::Bot::Client.new { |config|
      config.channel_secret = ENV["LINE_CHANNEL_SECRET"]
      config.channel_token = ENV["LINE_CHANNEL_TOKEN"]
    }
  end
end
```
第二件事，要建立Message資料表，您可以在終端機中執行以下指令：

```
rails generate model Message user_input:string ai_response:string
```
這個指令會建立一個名為Message的model，裡面有兩個欄位user_input和ai_response，型態都是string。接下來再執行以下指令：

```
rails db:migrate
```
這個指令會在資料庫中建立一個名為messages的資料表，您就可以在這個資料表中紀錄用戶輸入的訊息和OpenAI回傳的訊息了。

Prompt:
我想要修改一些東西:
1. message_text 的回應好短，可以加長嗎?
2. message_text 的回應開頭都會換行，要怎麼讓他不要換行?
3. 有辦法也記錄是哪一個line的使用者嗎?
4. 回傳目前需要被修改的程式碼片段就好，不需要回傳整個controller

ChatGPT:
您可以修改 max_tokens 的數值，增加 openai 回應的字數，例如改為 50:
```ruby
response = OpenAI::Client.new.completions(
  parameters: {
    model: "text-davinci-003",
    prompt: text,
    max_tokens: 50
  })
```
您可以使用 strip 方法刪除回應文字開頭和結尾的空白字元:
```ruby
message_text = response["choices"][0]["text"].strip
```
您可以使用 Line User Id 來記錄哪一個使用者發送了訊息，首先您需要在 case event 中取得 Line User Id:
```ruby
user_id = event["source"]["userId"]
```
接著您可以在儲存訊息到資料庫時，將使用者的 Line User Id 一併儲存:

```ruby
Message.create(user_id: user_id, text: text, response: message_text)
```
以下為您需要修改的程式碼片段:
```ruby
response = OpenAI::Client.new.completions(
  parameters: {
    model: "text-davinci-003",
    prompt: text,
    max_tokens: 50
  })
message_text = response["choices"][0]["text"].strip
client.reply_message(event["replyToken"], { type: "text", text: message_text })
user_id = event["source"]["userId"]
Message.create(user_id: user_id, text: text, response: message_text)
```

Prompt:
我無法儲存 user_id: user_id，是不是資料庫需要修改?

ChatGPT:
是的，如果你想要儲存使用者的 ID，你需要在 messages 資料表中新增一個欄位，例如叫做 user_id。你可以使用以下指令在 Rails 中新增欄位：

```
rails generate migration AddUserIdToMessages user_id:string
```
這會產生一個新的 migration 檔案，你可以打開檔案並新增欄位：

```ruby
class AddUserIdToMessages < ActiveRecord::Migration[6.1]
  def change
    add_column :messages, :user_id, :string
  end
end
```
接著執行 migration：

```
rails db:migrate
```
現在 messages 資料表中就會新增一個 user_id 欄位，你可以在 controller 中儲存使用者 ID 到這個欄位。
