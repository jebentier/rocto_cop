# frozen_string_literal: true

require_relative '../../../spec_helper'

RSpec.describe RoctoCop::Events::CheckSuite do
  let(:payload) { JSON.parse(load_event(:valid_check_suite_request)) }

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

      describe 'with a request action' do
        let(:payload) { JSON.parse(load_event(:valid_check_suite_request)) }

        it 'creates a new RoctoCop Linter check_run' do
          RoctoCop::Checks.names.each do |check_name|
            expect(client).to receive(:create_check_run).with('test/test_repo', check_name, 'shaofthehead')
          end
          subject.process(client)
        end
      end

      describe 'with a request action' do
        let(:payload) { JSON.parse(load_event(:valid_check_suite_rerequest)) }

        it 'creates a new RoctoCop Linter check_run' do
          RoctoCop::Checks.names.each do |check_name|
            expect(client).to receive(:create_check_run).with('test/test_repo', check_name, 'shaofthehead')
          end
          subject.process(client)
        end
      end
    end
  end
end
