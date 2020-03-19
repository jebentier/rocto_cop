# frozen_string_literal: true

require_relative '../../../spec_helper'

RSpec.describe RoctoCop::Checks::Rspec do
  it 'has a CHECK_NAME defined' do
    expect(described_class::CHECK_NAME).to eq('RoctoCop Tester')
  end

  describe 'instance' do
    let(:client) { Octokit::Client.new(bearer_token: 'bearer_token') }
    let(:repo) { 'test/test_repo' }
    let(:sha) { Digest::SHA1.hexdigest("hello") }
    let(:run_id) { 123 }
    let(:local_git_repo) { double(Git::Base) }
    let(:test_output_json) { "" }

    before(:each) do
      allow(Time).to receive(:now).and_return(Time.parse('2020-01-01 10:00:00'))
      expect(client).to receive(:update_check_run).with(repo, run_id, status: 'in_progress', started_at: Time.now.utc.iso8601)

      # Stubbing out the git repo checkout process
      expect(local_git_repo).to receive(:chdir) { |&block| block.call }
      expect(local_git_repo).to receive(:pull)
      expect(local_git_repo).to receive(:checkout).with(sha)
      expect(Git).to receive(:clone).with("https://x-access-token:bearer_token@github.com/#{repo}.git", anything).and_return(local_git_repo)

      # Bundle install before the tests are run
      expect_any_instance_of(described_class).to receive(:`).with('bundle install')

      # Execute the test run
      expect_any_instance_of(described_class).to receive(:`).with('bundle exec rspec --format json').and_return(test_output_json)
    end

    describe "when all tests pass" do
      let(:test_output_json) { load_rspec_result(:passed) }
      let(:expected_annotations) { [] }
      let(:expected_summary) { <<~SUMMARY.chomp }
        ### RoctoCop Tester Summary

        Executed: 33
        Passed: 33
        Pending: 0
        Failed: 0

        #### Run Profiling
        Total Run Duration: 2.000983
        Slowest Test File: RoctoCop::Server
        Slowest Test: RoctoCop::Server GET /is_alive returns 200 status code
      SUMMARY
      let(:expected_text) { <<~TEXT.chomp }
        RoctoCop Tester RSpec version: 3.9.1
        RoctoCop Tester RSpec seed: 62782
      TEXT

      it "reports a completed status with relevant success information" do
        expect(client).to(
          receive(:update_check_run)
            .with(
              repo,
              run_id,
              status: 'completed',
              conclusion: 'success',
              completed_at: Time.now.utc.iso8601,
              output: {
                title: 'RoctoCop Tester Results',
                summary: expected_summary,
                text: expected_text,
                annotations: []
              },
              actions: expected_annotations
            )
        )

        described_class.new(client, repo, sha, run_id).run
      end
    end

    describe "when there are test run failures" do
      let(:test_output_json) { load_rspec_result(:failed) }
      let(:expected_annotations) do
        [
          {
            title: "Test Failure",
            annotation_level: "failure",
            path: "spec/lib/rocto_cop/events/check_run_spec.rb",
            start_line: 66,
            end_line: 66,
            message: <<~ANNOTATION.chomp,
              RoctoCop::Events::CheckRun#process when called with a valid client with a requested action runs the provided action
                  NameError: uninitialized constant RoctoCop::Checks::Rspec
              Did you mean?  RSpec

              Run Time: 218ms
              Re-Run Locally With: `bundle exec rspec ./spec/lib/rocto_cop/events/check_run_spec.rb:66`
            ANNOTATION
            raw_details: "backtrace line 1\nbacktrace line 2"
          },
          {
            title: "Test Failure",
            annotation_level: "failure",
            path: "spec/lib/rocto_cop/events/check_run_spec.rb",
            start_line: 57,
            end_line: 57,
            message: <<~ANNOTATION.chomp,
              RoctoCop::Events::CheckRun#process when called with a valid client with a created run runs the provided check
                  NameError: uninitialized constant RoctoCop::Checks::Rspec
              Did you mean?  RSpec

              Run Time: 27ms
              Re-Run Locally With: `bundle exec rspec ./spec/lib/rocto_cop/events/check_run_spec.rb:57`
            ANNOTATION
            raw_details: "backtrace line 1\nbacktrace line 2"
          },
          {
            title: "Test Failure",
            annotation_level: "failure",
            path: "spec/lib/rocto_cop/events/check_run_spec.rb",
            start_line: 48,
            end_line: 48,
            message: <<~ANNOTATION.chomp,
              RoctoCop::Events::CheckRun#process when called with a valid client with a rerequested run creates a new RoctoCop Linter check_run
                  NameError: uninitialized constant RoctoCop::Checks::Rspec
              Did you mean?  RSpec

              Run Time: 36ms
              Re-Run Locally With: `bundle exec rspec ./spec/lib/rocto_cop/events/check_run_spec.rb:48`
            ANNOTATION
            raw_details: "backtrace line 1\nbacktrace line 2"
          },
          {
            title: "Test Failure",
            annotation_level: "failure",
            path: "spec/lib/rocto_cop/events/check_run_spec.rb",
            start_line: 38,
            end_line: 38,
            message: <<~ANNOTATION.chomp,
              RoctoCop::Events::CheckRun#process when called with a valid client when called with an unknown check name skips processing all together
                  NameError: uninitialized constant RoctoCop::Checks::Rspec
              Did you mean?  RSpec

              Run Time: 179ms
              Re-Run Locally With: `bundle exec rspec ./spec/lib/rocto_cop/events/check_run_spec.rb:38`
            ANNOTATION
            raw_details: "backtrace line 1\nbacktrace line 2"
          },
          {
            title: "Test Failure",
            annotation_level: "failure",
            path: "spec/lib/rocto_cop/events/check_suite_spec.rb",
            start_line: 38,
            end_line: 38,
            message: <<~ANNOTATION.chomp,
              RoctoCop::Events::CheckSuite#process when called with a valid client with a request action creates a new RoctoCop Linter check_run
                  NameError: uninitialized constant RoctoCop::Checks::Rspec
              Did you mean?  RSpec

              Run Time: 17ms
              Re-Run Locally With: `bundle exec rspec ./spec/lib/rocto_cop/events/check_suite_spec.rb:38`
            ANNOTATION
            raw_details: "backtrace line 1\nbacktrace line 2"
          },
          {
            title: "Test Failure",
            annotation_level: "failure",
            path: "spec/lib/rocto_cop/events/check_suite_spec.rb",
            start_line: 47,
            end_line: 47,
            message: <<~ANNOTATION.chomp,
              RoctoCop::Events::CheckSuite#process when called with a valid client with a request action creates a new RoctoCop Linter check_run
                  NameError: uninitialized constant RoctoCop::Checks::Rspec
              Did you mean?  RSpec

              Run Time: 27ms
              Re-Run Locally With: `bundle exec rspec ./spec/lib/rocto_cop/events/check_suite_spec.rb:47`
            ANNOTATION
            raw_details: "backtrace line 1\nbacktrace line 2"
          },
          {
            title: "Test Failure",
            annotation_level: "failure",
            path: "spec/lib/rocto_cop/checks/linter_spec.rb",
            start_line: 125,
            end_line: 125,
            message: <<~ANNOTATION.chomp,
              RoctoCop::Checks::Linter instance when there are annotations to process reports neutral
                  RuntimeError: uh oh

              Run Time: 79ms
              Re-Run Locally With: `bundle exec rspec ./spec/lib/rocto_cop/checks/linter_spec.rb:125`
            ANNOTATION
            raw_details: "backtrace line 1\nbacktrace line 2"
          },
          {
            title: "Test Failure",
            annotation_level: "failure",
            path: "spec/lib/rocto_cop/checks/linter_spec.rb",
            start_line: 64,
            end_line: 64,
            message: <<~ANNOTATION.chomp,
              RoctoCop::Checks::Linter instance when there are no annotations reports success
                  RuntimeError: uh oh

              Run Time: 66ms
              Re-Run Locally With: `bundle exec rspec ./spec/lib/rocto_cop/checks/linter_spec.rb:64`
            ANNOTATION
            raw_details: "backtrace line 1\nbacktrace line 2"
          },
          {
            title: "Test Failure",
            annotation_level: "failure",
            path: "spec/lib/rocto_cop/server_spec.rb",
            start_line: 128,
            end_line: 128,
            message: <<~ANNOTATION.chomp,
              RoctoCop::Server POST /event_handler with a valid check_run request event processes the event and returns 200
                  RSpec::Expectations::ExpectationNotMetError:
              expected: 500
                   got: 200

              (compared using ==)


              Run Time: 75ms
              Re-Run Locally With: `bundle exec rspec ./spec/lib/rocto_cop/server_spec.rb:128`
            ANNOTATION
            raw_details: "backtrace line 1\nbacktrace line 2"
          }
        ]
      end
      let(:expected_summary) { <<~SUMMARY.chomp }
        ### RoctoCop Tester Summary

        Executed: 33
        Passed: 24
        Pending: 0
        Failed: 9

        #### Run Profiling
        Total Run Duration: 2.0025299
        Slowest Test File: RoctoCop::Events::CheckRun
        Slowest Test: RoctoCop::Events::CheckRun#process when called with a valid client with a requested action runs the provided action
      SUMMARY
      let(:expected_text) { <<~TEXT.chomp }
        RoctoCop Tester RSpec version: 3.9.1
        RoctoCop Tester RSpec seed: 1868
      TEXT

      it "reports a completed status with relevant failure information" do
        expect(client).to(
          receive(:update_check_run)
            .with(
              repo,
              run_id,
              status: 'completed',
              conclusion: 'failure',
              completed_at: Time.now.utc.iso8601,
              output: {
                title: 'RoctoCop Tester Results',
                summary: expected_summary,
                text: expected_text,
                annotations: expected_annotations
              },
              actions: ["broken"]
            )
        )

        described_class.new(client, repo, sha, run_id).run
      end
    end
  end
end
