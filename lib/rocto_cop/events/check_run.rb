# frozen_string_literal: true

module RoctoCop
  module Events
    class CheckRun
      attr_reader :request_payload

      def initialize(request_payload)
        @request_payload = request_payload
      end

      def process(client)
        client.is_a?(Octokit::Client) or raise ArgumentError, 'Invalid client provided'

        if requested_app_id == RoctoCop::GithubApp::APP_IDENTIFIER && check_name.in?(RoctoCop::Checks.names)
          case action
          when 'rerequested'
            client.create_check_run(repository, check_name, head_sha)
          end
        end
      end

      private

      def action
        @request_payload['action']
      end

      def repository
        @request_payload.dig('repository', 'full_name')
      end

      def head_sha
        @request_payload.dig('check_run', 'head_sha')
      end

      def requested_app_id
        @request_payload.dig('check_run', 'app', 'id').to_s
      end

      def check_name
        @request_payload.dig('check_run', 'name')
      end
    end
  end
end
