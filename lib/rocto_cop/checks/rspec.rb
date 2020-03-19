# frozen_string_literal: true

require 'git'
require 'json'

module RoctoCop
  module Checks
    class Rspec
      CHECK_NAME      = 'RoctoCop Tester'
      MAX_ANNOTATIONS = 50

      attr_reader :client, :repo, :run_id, :sha

      def initialize(client, repo, sha, run_id)
        @client = client
        @repo   = repo
        @sha    = sha
        @run_id = run_id
      end

      def run
        update_check_run_status('in_progress', started_at: Time.now.utc.iso8601)
        clone_repo do
          reported_annotations.tap do |ra|
            update_check_run_status(
              'completed',
              conclusion: conclusion,
              completed_at: Time.now.utc.iso8601,
              output: {
                title: "#{CHECK_NAME} Results",
                summary: summary,
                text: text,
                annotations: ra
              },
              actions: []
            )
          end
        end
      ensure
        FileUtils.remove_entry(tmpdir, true)
      end

      private

      def update_check_run_status(status, options = {})
        client.update_check_run(repo, run_id, status: status, **options)
      end

      def clone_repo
        local_repo = Git.clone(repo_url, tmpdir)
        local_repo.chdir do
          local_repo.pull
          local_repo.checkout(sha)
          yield(local_repo) if block_given?
        end
      end

      def test_results
        @test_results ||= begin
          `bundle install`
          JSON.parse(`bundle exec rspec --format json`)
        end
      end

      def reported_annotations
        annotations[0...MAX_ANNOTATIONS]
      end

      def annotations
        test_results["examples"].map do |example|
          if example["status"] != "passed"
            {
              path: example["file_path"].gsub("./", ""),
              start_line: example["line_number"],
              end_line: example["line_number"],
              annotation_level: 'failure',
              title: "Test Failure",
              message: annotation_message(example),
              raw_details: example.dig("exception", "backtrace").join("\n")
            }
          end
        end.compact
      end

      def annotation_message(example)
        <<~ANNOTATION.chomp
          #{example["full_description"]}
              #{example.dig("exception", "class")}: #{example.dig("exception", "message")}

          Run Time: #{(example["run_time"] * 1000).to_i}ms
          Re-Run Locally With: `bundle exec rspec #{example["file_path"]}:#{example["line_number"]}`
        ANNOTATION
      end

      def summary
        <<~SUMMARY.chomp
          ### RoctoCop Tester Summary

          Executed: #{test_results.dig("summary", "example_count")}
          Passed: #{test_results.dig("summary", "example_count") - test_results.dig("summary", "failure_count")}
          Pending: #{test_results.dig("summary", "pending_count")}
          Failed: #{test_results.dig("summary", "failure_count")}

          #### Run Profiling
          Total Run Duration: #{test_results.dig("profile", "total")}
          Slowest Test File: #{test_results.dig("profile", "groups").first["description"]}
          Slowest Test: #{test_results.dig("profile", "examples").first["full_description"]}
        SUMMARY
      end

      def text
        <<~TEXT.chomp
          RoctoCop Tester RSpec version: #{test_results["version"]}
          RoctoCop Tester RSpec seed: #{test_results["seed"]}
        TEXT
      end

      def conclusion
        test_results.dig('summary', 'failure_count').zero? ? 'success' : 'failure'
      end

      def repo_url
        @repo_url ||= "https://x-access-token:#{client.bearer_token}@github.com/#{repo}.git"
      end

      def tmpdir
        @tmpdir ||= File.expand_path(run_id.to_s, Dir.tmpdir)
      end
    end
  end
end
