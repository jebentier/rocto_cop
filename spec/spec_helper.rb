# frozen_string_literal: true

require 'rack/test'
require 'openssl'
require_relative '../lib/rocto_cop'

# rubocop:disable Metrics/BlockLength
RSpec.configure do |config|
  config.include Rack::Test::Methods

  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
    expectations.max_formatted_output_length = nil
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.shared_context_metadata_behavior = :apply_to_host_groups
  config.filter_run_when_matching :focus
  config.example_status_persistence_file_path = 'spec/reports/last_run_status.txt'
  config.disable_monkey_patching!
  config.warnings = true

  config.default_formatter = 'doc' if config.files_to_run.one?

  config.profile_examples = 10

  config.order = :random
  Kernel.srand config.seed

  config.before(:each) do
    stub_const('RoctoCop::GithubApp::PRIVATE_KEY', OpenSSL::PKey::RSA.generate(2048))
    stub_const('RoctoCop::GithubApp::APP_IDENTIFIER', '123456')
    stub_const('RoctoCop::GithubApp::WEBHOOK_SECRET', 'thisisasecret')
  end

  def load_event(event_name)
    File.open(File.expand_path("./files/#{event_name}.json", __dir__), &:read)
  end

  def load_rspec_result(status)
    File.open(File.expand_path("./files/#{status}_rspec.json", __dir__), &:read)
  end

  def event_signature(event_name)
    "sha1=#{OpenSSL::HMAC.hexdigest('sha1', RoctoCop::GithubApp::WEBHOOK_SECRET, load_event(event_name))}"
  end
end
# rubocop:enable Metrics/BlockLength
