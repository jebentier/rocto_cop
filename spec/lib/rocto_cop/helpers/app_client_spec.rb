# frozen_string_literal: true

require 'jwt'
require_relative '../../../spec_helper'

class AppClientDummyServer
  include RoctoCop::Helpers::AppClient
end

RSpec.describe RoctoCop::Helpers::AppClient do
  let(:rsa_private_key) { OpenSSL::PKey::RSA.generate(2048) }

  subject { AppClientDummyServer.new.app_client }

  before(:each) {
    allow(Time).to receive(:now).and_return(Time.parse('2020-01-01 10:00:00'))
    stub_const('RoctoCop::GithubApp::PRIVATE_KEY', rsa_private_key)
    stub_const('RoctoCop::GithubApp::APP_IDENTIFIER', '123456')
  }

  it { is_expected.to be_a(Octokit::Client) }

  describe "Bearer Token" do
    before(:each) {
      @decoded_token = JWT.decode(subject.bearer_token, rsa_private_key.public_key, true, algorithm: 'RS256').first
    }

    it "uses a jwt token with a 10 minute expiration" do
      expect(@decoded_token["exp"]).to eq((Time.now + 10.minutes).to_i)
    end

    it "uses now as the initiated at time" do
      expect(@decoded_token["iat"]).to eq(Time.now.to_i)
    end

    it "uses the app identifier" do
      expect(@decoded_token["iss"]).to eq("123456")
    end
  end
end
