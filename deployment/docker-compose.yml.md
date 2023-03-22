```yml
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
      - 3000:3000
    command:
      sh -c "bundle exec rails db:create && bundle exec rails db:migrate && rm -f tmp/pids/server.pid && bundle exec rails s -p 3000 -b '0.0.0.0'"

volumes:
  redis_data:
  postgres_data:
```
