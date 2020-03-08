# frozen_string_literal: true

require 'octokit'
require 'openssl'
require 'json'

module RoctoCop
  module Helpers
    module Request
      def raw_payload
        @raw_payload ||= begin
          request.body.rewind
          request.body.read
        end
      end

      def payload
        @payload ||= begin
          JSON.parse(raw_payload)
                     rescue => e
                       fail "Unable to parse payload (#{e}): #{raw_payload}"
        end
      end

      def verify_webhook_signature
        signature_header = request.env[RoctoCop::GithubApp::GITHUB_SIGNATURE_HEADER]
        method, digest   = signature_header.split('=')
        expected_digest  = OpenSSL::HMAC.hexdigest(method, RoctoCop::GithubApp::WEBHOOK_SECRET, raw_payload)

        digest == expected_digest or halt 401
      end

      def client
        @client ||= begin
          installation_id    = payload.dig('installation', 'id')
          installation_token = app_client.create_app_installation_access_token(installation_id)[:token]
          Octokit::Client.new(bearer_token: installation_token)
        end
      end
    end
  end
end
