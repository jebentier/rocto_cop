# frozen_string_literal: true

require_relative '../../../../spec_helper'

RSpec.describe RoctoCop::Actions::Linter::FixAll do
  describe '#action_definition' do
    let(:expected_definition) do
      {
        label: 'Fix all these',
        description: 'Fix all Roctocop Linter notices for me.',
        identifier: 'fix_roctocop_linter'
      }
    end

    subject { described_class.action_definition }

    it 'returns the expected action' do
      is_expected.to eq(expected_definition)
    end
  end

  describe 'instance' do
    let(:client) { Octokit::Client.new(bearer_token: 'bearer_token') }
    let(:repo) { 'test/test_repo' }
    let(:branch) { "test-branch" }
    let(:run_id) { 123 }

    subject { described_class.new(client, repo, branch, run_id) }

    before(:each) do
      # Stubbing out the git repo checkout process
      double(Git::Base).tap do |git|
        expect(git).to receive(:chdir) { |&block| block.call }
        expect(git).to receive(:pull)
        expect(git).to receive(:checkout).with(branch)

        expect(git).to receive(:config).with('user.name', 'Roctocop Linter')
        expect(git).to receive(:config).with('user.email', 'linter@roctocop.io')
        expect(git).to receive(:commit_all).with('Automatic resolution of Roctocop Linter notices')
        expect(git).to receive(:push).with("https://x-access-token:bearer_token@github.com/#{repo}.git", branch)

        expect(Git).to receive(:clone).with("https://x-access-token:bearer_token@github.com/#{repo}.git", anything).and_return(git)
      end
    end

    it 'runs to completion' do
      expect(subject).to receive(:`).with('rubocop ./* --format json --auto-correct')
      subject.run
    end
  end
end
