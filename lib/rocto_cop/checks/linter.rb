# frozen_string_literal: true

require 'rubocop'
require 'git'

module RoctoCop
  module Checks
    class Linter
      CHECK_NAME      = "RoctoCop Linter"
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
        clone_repo
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
            actions: actions || []
          )
        end
      ensure
        FileUtils.remove_entry(tmpdir, true)
      end

      private

      def actions
        unless reported_annotations.count.zero?
          [
            RoctoCop::Actions::Linter::FixAll.action_definition
          ]
        end
      end

      def update_check_run_status(status, options = {})
        client.update_check_run(repo, run_id, status: status, **options)
      end

      def clone_repo
        r = Git.clone("https://x-access-token:#{client.bearer_token}@github.com/#{repo}.git", tmpdir)
        r.chdir do
          r.pull
          r.checkout(sha)
        end
      end

      def rubocop_output
        @rubocop_output ||= begin
          options, paths = RuboCop::Options.new.parse([tmpdir, '--format', 'json'])
          env = RuboCop::CLI::Environment.new(options, RuboCop::ConfigStore.new, paths)

          runner = RuboCop::Runner.new(env.options, env.config_store)
          begin
            runner.run(env.paths)
          rescue
            nil
          end

          runner.send(:formatter_set).first.output_hash
        end
      end

      def reported_annotations
        annotations[0...MAX_ANNOTATIONS]
      end

      def annotations
        rubocop_output[:files].flat_map do |file|
          file_path = file[:path].gsub(/#{tmpdir}\//, '')
          file[:offenses].map do |offense|
            {
              path: file_path,
              start_line: offense.dig(:location, :start_line),
              end_line: offense.dig(:location, :last_line),
              message: offense[:message],
              annotation_level: 'notice'
            }.tap do |annotation|
              if annotation[:start_line] == annotation[:end_line]
                annotation.merge!(
                  start_column: offense.dig(:location, :start_column),
                  end_column: offense.dig(:location, :last_column)
                )
              end
            end
          end
        end
      end

      def summary
        <<~SUMMARY.chomp
          ### RoctoCop Linter Summary

          Offense Count: #{rubocop_output.dig(:summary, :offense_count)}
          Files Processed: #{rubocop_output.dig(:summary, :target_file_count)}
          Files Inspected: #{rubocop_output.dig(:summary, :inspected_file_count)}
          Reported Offenses: #{reported_annotations.count} out of #{annotations.count}
        SUMMARY
      end

      def text
        "RoctoCop Linter RuboCop version: #{rubocop_output.dig(:metadata, :rubocop_version)}"
      end

      def conclusion
        rubocop_output.dig(:summary, :offense_count).zero? ? 'success' : 'neutral'
      end

      def tmpdir
        @tmpdir ||= File.expand_path("#{run_id}/linter", Dir.tmpdir)
      end
    end
  end
end
