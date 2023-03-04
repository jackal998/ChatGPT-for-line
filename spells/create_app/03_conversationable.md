Prompt:
我覺得回應還是太短了，有建議的長度嗎?
第二，有辦法讓openai知道line傳過來的，更先前的對話嗎?

ChatGPT:
關於回應的長度，這是很主觀的問題，根據不同的需求和情境，回應的長度可能需要有所調整，所以建議您可以根據您的實際使用情境，自行調整回應的長度。

關於 openai 知道之前的對話，您可以在 prompt 中加入之前的對話內容，讓 OpenAI 知道之前的對話內容，進而更精確地回答問題。例如：

```ruby
prompt = "User: #{previous_message.text}\nBot: #{previous_message.reply_text}\nUser: "
text = event.message["text"]
prompt += "#{text}\nBot: "

response = OpenAI::Completion.create(
  engine: "text-davinci-002",
  prompt: prompt,
  max_tokens: 60
)
```
在這個例子中，prompt 變數中包含了之前使用者的輸入和機器人的回應，這樣 OpenAI 就可以更好地理解上下文，更精確地回答問題。

Prompt:
有辦法讓prompt 的內容變成最近30分鐘的所有對話，或是限制總長不超過1000個token嗎?

ChatGPT:
是的，你可以透過程式碼篩選最近30分鐘的訊息，然後將這些訊息串接起來作為 prompt 傳遞給 OpenAI API。例如，你可以使用以下程式碼：

```ruby
# 取得最近 30 分鐘的訊息
recent_messages = Message.where("created_at >= ?", 30.minutes.ago)

# 將訊息串接起來
prompt = recent_messages.map { |m| m.message_text }.join("\n")

# 限制 prompt 的總長度不超過 1000 個 token
prompt = prompt.split(/\s+/).take(1000).join(' ')
```
這個程式碼會從資料庫中取得最近 30 分鐘的所有訊息，並將這些訊息的訊息文字串接起來作為 prompt 傳遞給 OpenAI API。如果 prompt 的總長度超過 1000 個 token，則會將它截斷為前 1000 個 token。

請注意，將許多不同的對話串接起來，可能會導致 OpenAI 的回應變得不太精確或不一致。因此，你可能需要進一步調整 prompt 的內容或使用其他技術，例如將訊息進行分類或主題建模，以提高 OpenAI API 的回應品質。

Prompt:
你說的對，我只要當前使用者的所有對話就好

ChatGPT:
好的，那麼你可以考慮使用資料庫中儲存的當前使用者的所有對話來作為 prompt。可以先從資料庫中抓出當前使用者的所有對話，然後再把它們串接起來作為 prompt 傳給 OpenAI API。

另外，關於限制總長度不超過 1000 個 token，你可以使用 OpenAI API 提供的 stop 參數來實現。你可以在傳給 API 的 parameters 中加入 stop 參數，設定為一個字串，當 API 回傳的內容中出現這個字串時，會自動停止生成回應。這樣就可以避免生成的回應太長的問題。

Prompt:
請給我相對應的程式碼，另外關於限制總長度不超過 1000 個 token是指傳出去給openai的訊息，我不限制生成的回應
以下是修改後的程式碼片段：

```ruby
when Line::Bot::Event::MessageType::Text
  reply_token = event["replyToken"]
  text = event.message["text"]
  user_id = event["source"]["userId"]

  # retrieve user's last 30 minutes conversations
  recent_messages = Message.where(user_id: user_id)
                            .where("created_at > ?", 30.minutes.ago)

  # concatenate recent messages into prompt
  prompt = recent_messages.map(&:message_text).join("\n")

  # limit total prompt length to 1000 tokens
  prompt = prompt.split[0..999].join(" ")

  # generate response using OpenAI
  response = OpenAI::Client.new.completions(
    engine: "text-davinci-002",
    prompt: prompt,
    max_tokens: 50,
    n: 1,
    stop: "\n",
    temperature: 0.5
  )

  # extract text from OpenAI response
  message_text = response["choices"][0]["text"].strip

  # create new message record in database
  Message.create(user_id: user_id, message_text: message_text)

  # send reply message to Line
  message = {
    type: "text",
    text: message_text
  }
 
  client.reply_message(reply_token, message)
```
這段程式碼會從資料庫中查詢出使用者最近 30 分鐘的對話，並將這些對話連接成一個 prompt 字串，最後限制該字串的總長度不超過 1000 個 tokens，再將此 prompt 傳送給 OpenAI 進行生成回應。最後，新建一條 Message 記錄並回覆訊息給使用者。

Prompt:
關於這個片段我有幾個地方需要修改:
1. prompt 是不是應該要包含user_input 以及 ai_response?
2. prompt 是不是應該也要包含當下傳入的訊息?

請幫我修改這段程式碼謝謝!

ChatGPT:
好的，以下是修改後的程式碼：

```ruby
def generate_response(user_input, user_id)
  messages = Message.where(user_id: user_id).last(10).pluck(:message_text)
  prompt = messages.join("\n")
  prompt += "\n#{user_input}"

  # Check prompt length is not more than 1000 tokens
  prompt_tokens = prompt.split(" ")
  prompt = prompt_tokens[0..999].join(" ") if prompt_tokens.length > 1000

  response = OpenAI::Client.new.completions(
    engine: "davinci",
    prompt: prompt,
    max_tokens: 150,
    n: 1,
    stop: "\n",
  ).choices.first.text.strip

  Message.create(user_id: user_id, message_text: user_input)
  Message.create(user_id: user_id, message_text: response)

  return response
end
```
修改後的 prompt 已經包含了使用者之前的對話（最多10條）以及使用者這次傳入的訊息。
為了限制 prompt 總長度不超過1000個token，我將 prompt 切成一個個單字，只選取前1000個單字作為 prompt。如果你想要增加 prompt 長度的話，可以調整這個限制。

Prompt:
更正一下，現在的Message欄位是這樣:
Message.create(user_id: user_id, user_input: text, ai_response: message_text)
所以應該同時可以拿到user_input & ai_response

再修改一下

ChatGPT:
好的，那麼你可以在 prompt 中加入 user_input 和最近的 ai_response，如下所示：

```ruby
prompt = "User Input: #{user_input}\nAI Response: #{last_ai_response}\n\n"
prompt += "Recent Conversation:\n#{recent_messages.join("\n")}"
```
這樣，prompt 就包含了當前的 user_input、最近的 ai_response 和最近的對話紀錄，可以傳送給 OpenAI 進行回應生成了。

同時，你也可以在 Message.create 時加入 last_ai_response 的值，像這樣：

```ruby
Message.create(user_id: user_id, user_input: user_input, ai_response: message_text, last_ai_response: last_ai_response)
```
這樣就可以將最新生成的回應紀錄到 last_ai_response 欄位中，方便之後使用。

Prompt:
來一次修改之後的完整的`def generate_response(user_input, user_id)`

ChatGPT:
好的，以下是修改之後的完整的 def generate_response(user_input, user_id)：

```ruby
def generate_response(user_input, user_id)
  # 取得最近 30 分鐘內當前使用者的所有對話
  conversations = Message.where(user_id: user_id)
                          .where("created_at >= ?", 30.minutes.ago)
                          .pluck(:user_input, :ai_response)
                          .map { |input, response| "#{input} #{response}" }

  # 加入當前傳入的訊息
  conversations << user_input

  # 將所有對話合併為一個字串，並限制總長度不超過 1000 個 token
  prompt = conversations.join("\n")
  prompt = prompt.slice(-(MAX_TOKENS - 50)..-1) if prompt.size > MAX_TOKENS

  # 使用 OpenAI 生成回應
  response = OpenAI::Client.new.completions(
    engine: "text-davinci-002",
    prompt: prompt,
    max_tokens: 100,
    temperature: 0.5,
    n: 1,
    stop: STOP_WORDS
  ).choices.first.text.strip

  # 將回應儲存到資料庫
  Message.create(user_id: user_id, user_input: user_input, ai_response: response)

  response
end
```
這個方法可以接收使用者傳入的訊息 user_input 和當前使用者的 ID user_id，然後使用這些資訊生成 AI 的回應。generate_response 方法會先取得最近 30 分鐘內當前使用者的所有對話，加上當前傳入的訊息，並限制總長度不超過 1000 個 token。然後，它使用 OpenAI 生成回應，並將回應儲存到資料庫中。最後，它會回傳生成的回應。

Prompt:
關於這個`  prompt = prompt.slice(-(MAX_TOKENS - 50)..-1) if prompt.size > MAX_TOKENS`

有取最後的 1000 個 token的寫法嗎？

ChatGPT:
可以使用以下程式碼來取最後的 1000 個 token：

```ruby
MAX_TOKENS = 1000
prompt = "#{user_input}\n#{ai_response}\n#{user_dialogues.last(30).join("\n")}"
prompt_tokens = prompt.split(" ")
if prompt_tokens.length > MAX_TOKENS
  prompt = prompt_tokens.last(MAX_TOKENS).join(" ")
end
```
這樣會先將 prompt 分成 tokens，如果 tokens 數量超過 1000，就只取最後的 1000 個 tokens。另外，也加入了 user_dialogues 的最近30筆訊息作為 prompt 的一部分。

Prompt:
現在是這樣，請幫我修改成剛剛講的這種形式:
    conversations = Message
      .where(user_id: user_id)
      .where("created_at >= ?", 30.minutes.ago)
      .pluck(:user_input, :ai_response)
      .map { |input, response| "#{input} #{response}" }
  
    # 加入當前傳入的訊息
    conversations << user_input
  
    # 將所有對話合併為一個字串，並限制總長度不超過 1000 個 token
    prompt = conversations.join("\n").split[0..999].join(" ")

ChatGPT:
好的，請參考下面的程式碼：

```ruby
def generate_response(user_input, user_id)
  # 取得最近 30 分鐘的對話
  conversations = Message
    .where(user_id: user_id)
    .where("created_at >= ?", 30.minutes.ago)
    .pluck(:user_input, :ai_response)
    .map { |input, response| "#{input} #{response}" }

  # 加入當前傳入的訊息
  conversations << user_input

  # 將所有對話合併為一個字串，並限制總長度不超過 1000 個 token
  prompt = conversations.join("\n").split[0..999].join(" ")

  # 補上AI Response格式
  prompt = "User: #{user_input}\n\n" + prompt

  # 執行 OpenAI 的 API
  response = OpenaiService.new.generate_text(prompt)

  # 取得回應的文字
  message_text = response["choices"].first["text"]

  # 新增一筆對話記錄
  Message.create(user_id: user_id, user_input: user_input, ai_response: message_text)

  # 回傳 AI 的回應
  return message_text
end
```
這個修改的版本，在取得最近 30 分鐘的對話時，會先使用 pluck 取得 user_input 與 ai_response 兩個欄位，接著用 map 將這些對話組合成一個字串，最後再加入當前傳入的訊息。

接著，將所有對話合併成一個字串後，使用 split 將其拆成單個的 token，再從後往前取出前 1000 個 token，即可達到取最近的 1000 個 token 的目的。

最後，新增一筆對話記錄並回傳 AI 的回應即可。

Prompt:
我不認為.split[0..999]是從後往前取出前 1000 個 token的寫法

ChatGPT:
非常抱歉，我犯了一個錯誤。.split[0..999] 實際上是取出前 1000 個 token，而不是從後往前取出。如果要從後往前取出前 1000 個 token，可以使用 .split.reverse[0..999].reverse。在此獻上修改後的程式碼，請您參考：

```ruby
def generate_response(user_input, user_id)
  conversations = Message
    .where(user_id: user_id)
    .where("created_at >= ?", 30.minutes.ago)
    .pluck(:user_input, :ai_response)
    .map { |input, response| "#{input} #{response}" }

  # 加入當前傳入的訊息
  conversations << user_input

  # 將所有對話合併為一個字串，並限制總長度不超過 1000 個 token
  prompt = conversations.join("\n").split.reverse[0..999].reverse.join(" ")
  
  # 呼叫 OpenAI API
  response = Openai::Completion.create(
    engine: "text-davinci-002",
    prompt: prompt,
    max_tokens: 150,
    n: 1,
    stop: "\n",
    temperature: 0.5,
  )

  message_text = response.choices[0].text.strip

  # 將訊息存入資料庫
  Message.create(user_id: user_id, user_input: user_input, ai_response: message_text)

  return message_text
end
```
