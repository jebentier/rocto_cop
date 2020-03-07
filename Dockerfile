FROM ruby:2.6.5

RUN gem install bundler:2.0.2

WORKDIR /app
EXPOSE 3000

COPY Gemfile Gemfile.lock ./
RUN bundle install

COPY . .

CMD ["bundle", "exec", "rackup", "config.ru", "-p", "3000"]
