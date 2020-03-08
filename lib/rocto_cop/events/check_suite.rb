# frozen_string_literal: true

module RoctoCop
  module Events
    class CheckSuite
      attr_reader :request_payload

      PROCESSABLE_ACTIONS = ['requested', 'rerequested'].freeze

      def initialize(request_payload)
        @request_payload = request_payload
      end

      def process(client)
        client.is_a?(Octokit::Client) or raise ArgumentError, 'Invalid client provided'

        if action.in?(PROCESSABLE_ACTIONS)
          RoctoCop::Checks.names.each do |check_name|
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
        @request_payload.dig('check_suite', 'head_sha')
      end
    end
  end
end
