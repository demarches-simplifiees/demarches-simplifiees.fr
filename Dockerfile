FROM ruby:2.3

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        postgresql-client \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY Gemfile* ./
RUN bundle install
COPY . .
RUN bundle binstub railties --force
RUN rake rails:update:bin
RUN rake dev:init

EXPOSE 3000
CMD ["rails", "server", "-b", "0.0.0.0"]
