FROM ruby:2.6.5

RUN mkdir -p /rocto_cop
ENV PATH "/rocto_cop/bin:${PATH}"
WORKDIR /rocto_cop

EXPOSE 3000

RUN gem install bundler:2.0.2

COPY Gemfile Gemfile.lock ./
RUN bundle install

COPY . .

ENTRYPOINT ["rocto_cop"]

CMD ["start"]
