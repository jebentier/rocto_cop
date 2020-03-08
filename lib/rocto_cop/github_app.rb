# frozen_string_literal: true

require 'dotenv/load'
require 'openssl'

module RoctoCop
  module GithubApp
    GITHUB_SIGNATURE_HEADER = 'HTTP_X_HUB_SIGNATURE'
    GITHUB_ACTION_HEADER    = 'HTTP_X_GITHUB_ACTION'
    GITHUB_EVENT_HEADER     = 'HTTP_X_GITHUB_EVENT'

    PRIVATE_KEY    = OpenSSL::PKey::RSA.new(ENV['GITHUB_PRIVATE_KEY'].gsub('\n', "\n"))
    WEBHOOK_SECRET = ENV['GITHUB_WEBHOOK_SECRET']
    APP_IDENTIFIER = ENV['GITHUB_APP_IDENTIFIER']
  end
end
