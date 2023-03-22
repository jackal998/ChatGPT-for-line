Prompt:
我用以下的docker compose想要測試localhost + ssl的環境，應該要怎麼設定?

version: '3.8'

services:
  postgres:
    image: postgres:13.1-alpine
    restart: unless-stopped
    volumes:
      - postgres_data:/var/lib/postgresql/data
    env_file:
      - .env
    environment:
      - POSTGRES_DB
      - POSTGRES_USER
      - POSTGRES_PASSWORD

  redis:
    image: redis:5-alpine
    command: redis-server
    volumes:
      - redis_data:/var/lib/redis/data

  sidekiq:
    image: us.gcr.io/chatgpt-in-line/rails
    command: bundle exec sidekiq
    depends_on:
      - redis
      - postgres
    env_file:
      - .env
    environment:
      - REDIS_URL

  rails:
    # build:
    #   context: .
    #   dockerfile: Dockerfile
    image: us.gcr.io/chatgpt-in-line/rails
    depends_on:
      - redis
      - sidekiq
      - postgres
    env_file:
      - .env
    environment:
      - REDIS_URL
      - RAILS_MASTER_KEY
    ports:
      - 443:3000
    command:
      sh -c "bundle exec rails db:create && bundle exec rails db:migrate && rm -f tmp/pids/server.pid && bundle exec rails s -p 3000 -b 'ssl://localhost:3000?key=localhost.key&cert=localhost.crt'"

volumes:
  redis_data:
  postgres_data:

rails docker file:
```Dockerfile
ARG APP_ROOT=/app
ARG RUBY_VERSION=3.1.2

FROM ruby:${RUBY_VERSION}-alpine AS base
ARG APP_ROOT

RUN apk add --no-cache build-base postgresql-dev

RUN mkdir -p ${APP_ROOT}
COPY Gemfile Gemfile.lock ${APP_ROOT}/

WORKDIR ${APP_ROOT}
RUN gem install bundler:2.3.17 \
    && bundle config --local deployment 'true' \
    && bundle config --local frozen 'true' \
    && bundle config --local no-cache 'true' \
    && bundle install -j "$(getconf _NPROCESSORS_ONLN)" \
    && find ${APP_ROOT}/vendor/bundle -type f -name '*.c' -delete \
    && find ${APP_ROOT}/vendor/bundle -type f -name '*.h' -delete \
    && find ${APP_ROOT}/vendor/bundle -type f -name '*.o' -delete \
    && find ${APP_ROOT}/vendor/bundle -type f -name '*.gem' -delete

RUN bundle exec bootsnap precompile --gemfile app/ lib/

FROM ruby:${RUBY_VERSION}-alpine
ARG APP_ROOT

RUN apk add --no-cache shared-mime-info tzdata postgresql-libs

COPY --from=base /usr/local/bundle/config /usr/local/bundle/config
COPY --from=base /usr/local/bundle /usr/local/bundle
COPY --from=base ${APP_ROOT}/vendor/bundle ${APP_ROOT}/vendor/bundle
COPY --from=base ${APP_ROOT}/tmp/cache ${APP_ROOT}/tmp/cache

RUN mkdir -p ${APP_ROOT}

ENV RAILS_LOG_TO_STDOUT=true
ENV RAILS_SERVE_STATIC_FILES=yes
ENV APP_ROOT=$APP_ROOT

COPY . ${APP_ROOT}

# Apply Execute Permission
RUN adduser -h ${APP_ROOT} -D -s /bin/nologin ruby ruby && \
    chown ruby:ruby ${APP_ROOT} && \
    chown -R ruby:ruby ${APP_ROOT}/log && \
    chown -R ruby:ruby ${APP_ROOT}/tmp && \
    chmod -R +r ${APP_ROOT}

WORKDIR ${APP_ROOT}

CMD ["bundle", "exec", "rails", "server", "-b", "ssl://localhost:3000?key=localhost.key&cert=localhost.crt"]
```

ChatGPT:
首先，你需要將localhost.crt和localhost.key檔案放到一個目錄下（例如certs目錄），然後將這個目錄掛載到rails服務中。你可以在docker-compose.yml的rails服務中添加以下內容：

```
volumes:
  - ./certs:/certs
```

接著，你需要在Dockerfile中設定環境變數以指定SSL證書和金鑰的位置。你可以在Dockerfile中添加以下內容：

```
ENV SSL_CERT_PATH=/certs/localhost.crt
ENV SSL_KEY_PATH=/certs/localhost.key
```

最後，你需要在docker-compose.yml的rails服務中更新command以使用新的環境變數。你可以將原先的command替換為以下內容：

```
command:
  sh -c "bundle exec rails db:create && bundle exec rails db:migrate && rm -f tmp/pids/server.pid && bundle exec rails s -p 3000 -b 'ssl://0.0.0.0:3000?key=$SSL_KEY_PATH&cert=$SSL_CERT_PATH'"
```

現在你可以使用docker-compose up命令啟動服務，並且可以在瀏覽器中訪問https://localhost來測試。
