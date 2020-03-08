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
          when 'created'
            RoctoCop::Checks.run(check_name, client, repository, head_sha, run_id)
          when 'rerequested'
            client.create_check_run(repository, check_name, head_sha)
          when 'requested_action'
            RoctoCop::Actions.run(requested_action, client, repository, branch, run_id)
          end
        end
      end

      private

      def action
        request_payload['action']
      end

      def repository
        request_payload.dig('repository', 'full_name')
      end

      def head_sha
        request_payload.dig('check_run', 'head_sha')
      end

      def requested_app_id
        request_payload.dig('check_run', 'app', 'id').to_s
      end

      def check_name
        request_payload.dig('check_run', 'name')
      end

      def run_id
        request_payload.dig('check_run', 'id')
      end

      def requested_action
        request_payload.dig('requested_action', 'identifier')
      end

      def branch
        request_payload.dig('check_run', 'check_suite', 'head_branch')
      end
    end
  end
end
