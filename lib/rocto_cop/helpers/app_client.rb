# frozen_string_literal: true

require 'octokit'
require 'jwt'
require 'time'

module RoctoCop
  module Helpers
    module AppClient
      def app_client
        @app_client ||= begin
          now = Time.now
          jwt = JWT.encode(
            {
              iat: now.to_i,
              exp: (now + 10.minutes).to_i,
              iss: RoctoCop::GithubApp::APP_IDENTIFIER
            },
            RoctoCop::GithubApp::PRIVATE_KEY,
            'RS256'
          )

          Octokit::Client.new(bearer_token: jwt)
        end
      end
    end
  end
end
