# frozen_string_literal: true

require_relative '../../../spec_helper'

RSpec.describe RoctoCop::Events::CheckRun do
  let(:payload) { JSON.parse(load_event(:valid_check_run_created)) }

  subject { described_class.new(payload) }

  describe 'initialization' do
    it 'succeeds when a payload is passed' do
      is_expected.to be_a(described_class)
    end
  end

  describe '#process' do
    let(:client) { nil }

    it 'raises an Argument error when an Octokit Client is not provided' do
      expect { subject.process(client) }.to raise_error(ArgumentError, 'Invalid client provided')
    end

    describe 'when called with a valid client' do
      let(:client) { Octokit::Client.new }

      describe 'with a random action' do
        let(:payload) { JSON.parse(load_event(:valid_check_suite_other)) }

        it 'skips processing all together' do
          expect(client).to_not receive(:create_check_run)
          subject.process(client)
        end
      end

      describe 'when called with an unknown check name' do
        let(:payload) { JSON.parse(load_event(:valid_check_run_rerequested)) }

        it 'skips processing all together' do
          expect(client).to_not receive(:create_check_run)
          expect(subject).to receive(:check_name).and_return("unknown_check_name")
          subject.process(client)
        end
      end

      describe 'with a rerequested run' do
        let(:payload) { JSON.parse(load_event(:valid_check_run_rerequested)) }

        it 'creates a new RoctoCop Linter check_run' do
          expect(client).to receive(:create_check_run).with('test/test_repo', 'RoctoCop Linter', 'thisshaishead')
          subject.process(client)
        end
      end

      describe 'with a created run' do
        let(:payload) { JSON.parse(load_event(:valid_check_run_created)) }

        it 'runs the provided check' do
          expect(RoctoCop::Checks).to receive(:run).with('RoctoCop Linter', client, 'test/test_repo', 'thisshaishead', 123_456_123)
          subject.process(client)
        end
      end

      describe 'with a requested action' do
        let(:payload) { JSON.parse(load_event(:valid_requested_action_linter_fix)) }

        it 'runs the provided action' do
          expect(RoctoCop::Actions).to receive(:run).with('fix_roctocop_linter', client, 'test/test_repo', 'testing-patch-1', 789_456_123)
          subject.process(client)
        end
      end
    end
  end
end
