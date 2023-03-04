Prompt:
class OpenaiPromptGenerator
  MAX_TOKENS = 1000

  def initialize(user_id, user_input)
    @user_input = user_input
    @user_id = user_id
  end

  def execute
    # 取得最近 30 分鐘內當前使用者的所有對話
    conversations = Message
      .where(user_id: @user_id)
      .where("created_at >= ?", 30.minutes.ago)
      .pluck(:user_input, :ai_response)
      .map { |input, response| "user_input:#{input}\nai_response:#{response}" }
  
    # 加入當前傳入的訊息
    conversations << "user_input:#{@user_input}"

    # 將所有對話合併為一個字串，並限制總長度不超過 1000 個 token
    conversations.join("\n").split.reverse[0..MAX_TOKENS].reverse.join(" ")
  end
end

ChatGPT:
這是一個 OpenaiPromptGenerator 的 Ruby 類別，其目的是生成一個用於 OpenAI GPT-3 模型的 prompt。在 initialize 方法中，我們將儲存傳入的使用者 ID 和使用者輸入。在 execute 方法中，我們會從資料庫中搜尋最近 30 分鐘內的使用者對話，然後將它們轉換成一個字串，限制總長度不超過 1000 個 token。最後，我們將當前傳入的使用者輸入加入到這個字串中，然後回傳生成的 prompt。

這個 prompt 的目的是讓 OpenAI GPT-3 模型更好地理解使用者的上下文和對話歷史，進而生成更好的回應。由於 GPT-3 是一個語言模型，它需要大量的文本作為輸入，才能生成高品質的回應。因此，透過這個 prompt，我們可以讓模型較容易產生符合使用者期望的回應。

Prompt:
沒錯，請問OpenaiPromptGenerator 的測試該怎麼寫呢?

ChatGPT:
針對 OpenaiPromptGenerator 的測試，可以考慮以下幾個方向：

模擬 Message 模型的資料，來測試是否正確取得最近 30 分鐘內的使用者對話。
測試輸出字串的長度是否符合預期。
測試輸出字串的內容是否符合預期。
以下是一個可能的測試範例：

```ruby
require 'rails_helper'

RSpec.describe OpenaiPromptGenerator, type: :service do
  let(:user_id) { 'U1234567890abcdef1234567890abcdef' }
  let(:user_input) { 'Hello, world!' }

  describe '#execute' do
    context 'with recent conversations' do
      let!(:messages) do
        # 建立 31 分鐘前的對話
        create_list(:message, 3, user_id: user_id, created_at: 31.minutes.ago)

        # 建立 29 分鐘前的對話
        create_list(:message, 2, user_id: user_id, created_at: 29.minutes.ago)

        # 建立 28 分鐘前的對話，其中包含一個非當前使用者的對話
        create_list(:message, 2, created_at: 28.minutes.ago)
      end

      it 'returns a string with recent conversations and current user input' do
        prompt_generator = OpenaiPromptGenerator.new(user_id, user_input)
        prompt = prompt_generator.execute

        # 驗證回傳字串是否符合預期
        expect(prompt.length).to be <= 1000
        expect(prompt).to include("user_input:#{user_input}")

        # 驗證是否包含最近 30 分鐘內當前使用者的所有對話
        messages
          .select { |message| message.user_id == user_id }
          .each do |message|
            expect(prompt).to include("user_input:#{message.user_input}")
            expect(prompt).to include("ai_response:#{message.ai_response}")
          end
      end
    end

    context 'with no recent conversations' do
      it 'returns a string with only current user input' do
        prompt_generator = OpenaiPromptGenerator.new(user_id, user_input)
        prompt = prompt_generator.execute

        expect(prompt.length).to be <= 1000
        expect(prompt).to include("user_input:#{user_input}")
        expect(prompt).not_to include("ai_response:")
      end
    end
  end
end
```
這個測試範例建立了 9 個 Message 資料，模擬了不同時間點、不同使用者的對話，以驗證 OpenaiPromptGenerator 是否能夠正確取得最近 30 分鐘內當前使用者的所有對話，並正確輸出字串。

Prompt:
NoMethodError:
       undefined method `create_list' for #<RSpec::ExampleGroups::OpenaiPromptGenerator::Execute::WithRecentConversations "returns 
a string with recent conversations and current user input" (./spec/services/openai_prompt_generator_spec.rb:20)

ChatGPT:
根據這個錯誤訊息，看起來你正在使用 create_list 這個方法，但 RSpec 並不認識這個方法。可能是你忘記引入 FactoryBot 或是其他設定有誤。

請確認在 spec/rails_helper.rb 中有包含以下設定:

```ruby
RSpec.configure do |config|
  config.include FactoryBot::Syntax::Methods
  # ...
end
```
如果已經有這個設定，請確認 factory_bot gem 是否有被正確地引入並且安裝，也可以嘗試重新執行 bundle install 來確認。

Prompt:
Failure/Error: create_list(:message, 3, user_id: user_id, created_at: 31.minutes.ago)

     KeyError:
       Factory not registered: "message"

ChatGPT:
這個錯誤訊息顯示出現了 KeyError，指出 message 這個工廠沒有被註冊，可能是因為 RSpec 的環境設定有誤。請確認在 rails_helper.rb 檔案中有設定 config.include FactoryBot::Syntax::Methods，以及在 spec_helper.rb 檔案中有設定 config.before(:suite) { FactoryBot.find_definitions }。如果仍然無法解決問題，請確認 spec/factories 目錄下有 message.rb 檔案，其中有定義 message 工廠。

Prompt:
我的意思是這個 
>請確認 spec/factories 目錄下有 message.rb 檔案，其中有定義 message 工廠。

的message.rb 的內容是甚麼?

ChatGPT:
在使用 FactoryBot 建立物件時，需要事先在 spec/factories 目錄下建立一個 factory 文件。在這個情境下，我們需要創建一個 message.rb 檔案，其內容應該類似下面的程式碼：

```ruby
FactoryBot.define do
  factory :message do
    user_id { "U1234567890abcdef1234567890abcdef" }
    user_input { "Hello, world!" }
    ai_response { "Hi there!" }
    created_at { Time.current }
  end
end
```
這個程式碼會定義一個 message 的工廠，當我們在測試中使用 create(:message) 時，FactoryBot 會使用這個工廠建立一個 message 物件。注意，上面的程式碼中，我們使用了 FactoryBot 的 DSL（Domain-Specific Language），它可以讓我們簡單地定義一個工廠，並指定屬性的預設值。這裡，我們定義了三個屬性，分別是 user_id、user_input 和 ai_response，還有一個 created_at 屬性，其預設值為現在的時間。
