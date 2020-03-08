# frozen_string_literal: true

require_relative '../../../spec_helper'

RSpec.describe RoctoCop::Checks::Linter do
  it 'has a CHECK_NAME defined' do
    expect(described_class::CHECK_NAME).to eq('RoctoCop Linter')
  end

  describe 'instance' do
    let(:client) { Octokit::Client.new(bearer_token: 'bearer_token') }
    let(:repo) { 'test/test_repo' }
    let(:sha) { Digest::SHA1.hexdigest("hello") }
    let(:run_id) { 123 }
    let(:annotations) do
      {
        files: [],
        summary: { offense_count: 0, target_file_count: 0, inspected_file_count: 0 },
        metadata: { rubocop_version: '0.80.1' }
      }
    end
    let(:expected_text) { "RoctoCop Linter RuboCop version: 0.80.1" }

    before(:each) do
      allow(Time).to receive(:now).and_return(Time.parse('2020-01-01 10:00:00'))
      expect(client).to receive(:update_check_run).with(repo, run_id, status: 'in_progress', started_at: Time.now.utc.iso8601)

      # Stubbing out the git repo checkout process
      double(Git::Base).tap do |git|
        expect(git).to receive(:chdir) { |&block| block.call }
        expect(git).to receive(:pull)
        expect(git).to receive(:checkout).with(sha)
        expect(Git).to receive(:clone).with("https://x-access-token:bearer_token@github.com/#{repo}.git", anything).and_return(git)
      end

      # Stubbing out the RuboCop execution
      double(RuboCop::Runner).tap do |runner|
        expect(runner).to receive(:run).with(anything)
        expect(RuboCop::Runner).to receive(:new).with(any_args).and_return(runner)
        double(RuboCop::Formatter::JSONFormatter).tap do |formatter|
          expect(formatter).to receive(:output_hash).and_return(annotations)
          expect(runner).to receive(:formatter_set).and_return([formatter])
        end
      end
    end

    describe 'when there are no annotations' do
      let(:annotations) do
        {
          files: [],
          summary: { offense_count: 0, target_file_count: 10, inspected_file_count: 10 },
          metadata: { rubocop_version: '0.80.1' }
        }
      end
      let(:expected_summary) { <<~SUMMARY.chomp }
        ### RoctoCop Linter Summary

        Offense Count: 0
        Files Processed: 10
        Files Inspected: 10
        Reported Offenses: 0 out of 0
      SUMMARY


      it 'reports success' do
        expect(client).to(
          receive(:update_check_run)
            .with(
              repo,
              run_id,
              status: 'completed',
              conclusion: 'success',
              completed_at: Time.now.utc.iso8601,
              output: {
                title: "RoctoCop Linter Results",
                summary: expected_summary,
                text: expected_text,
                annotations: []
              },
              actions: []
            )
        )

        described_class.new(client, repo, sha, run_id).run
      end
    end

    describe 'when there are annotations to process' do
      let(:annotations) do
        {
          files: [
            {
              path: 'file1.rb',
              offenses: [
                { message: "Don't do that", location: { start_line: 10, last_line: 10, start_column: 1, last_column: 9 } },
                { message: "Don't do that either", location: { start_line: 14, last_line: 20, start_column: 1, last_column: 9 } }
              ]
            },
            {
              path: 'file2.rb',
              offenses: [
                { message: "Don't do that", location: { start_line: 10, last_line: 10, start_column: 1, last_column: 9 } },
              ]
            }
          ],
          summary: { offense_count: 3, target_file_count: 10, inspected_file_count: 10 },
          metadata: { rubocop_version: '0.80.1' }
        }
      end
      let(:expected_annotations) do
        [
          { path: "file1.rb", message: "Don't do that", annotation_level: "notice", start_line: 10, end_line: 10, start_column: 1, end_column: 9 },
          { path: "file1.rb", message: "Don't do that either", annotation_level: "notice", start_line: 14, end_line: 20 },
          { path: "file2.rb", message: "Don't do that", annotation_level: "notice", start_line: 10, end_line: 10, start_column: 1, end_column: 9 }
        ]
      end
      let(:expected_summary) { <<~SUMMARY.chomp }
        ### RoctoCop Linter Summary

        Offense Count: 3
        Files Processed: 10
        Files Inspected: 10
        Reported Offenses: 3 out of 3
      SUMMARY

      it 'reports neutral' do
        expect(client).to(
          receive(:update_check_run)
            .with(
              repo,
              run_id,
              status: 'completed',
              conclusion: 'neutral',
              completed_at: Time.now.utc.iso8601,
              output: {
                title: "RoctoCop Linter Results",
                summary: expected_summary,
                text: expected_text,
                annotations: expected_annotations
              },
              actions: [
                {
                  label: 'Fix all these',
                  description: 'Fix all Roctocop Linter notices for me.',
                  identifier: 'fix_roctocop_linter'
                }
              ]
            )
        )

        described_class.new(client, repo, sha, run_id).run
      end
    end
  end
end
