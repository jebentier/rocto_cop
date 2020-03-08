# frozen_string_literal: true

require_relative '../../../spec_helper'

class RequestDummyServer
  include RoctoCop::Helpers::Request

  def app_client; end

  def request; end

  def halt(_code); end
end

RSpec.describe RoctoCop::Helpers::Request do
  let(:request) { double(Sinatra::Request) }
  let(:body_proxy) { double(Rack::BodyProxy) }
  let(:body) { { hello: "world" }.to_json }
  let(:app_client) { double(Octokit::Client) }

  subject { RequestDummyServer.new }

  before(:each) do
    allow(subject).to receive(:app_client).and_return(app_client)
    allow(subject).to receive(:request).and_return(request)
    allow(request).to receive(:body).and_return(body_proxy)
    allow(body_proxy).to receive(:rewind)
    allow(body_proxy).to receive(:read).and_return(body)
  end

  describe 'raw_payload' do
    it "returns the unparsed json body" do
      expect(subject.raw_payload).to eq(body)
    end
  end

  describe 'payload' do
    it "returns the json parsed body" do
      expect(subject.payload).to eq(JSON.parse(body))
    end
  end

  describe 'client' do
    let(:body) { { installation: { id: '123123' } }.to_json }
    let(:token) { 'thisisadummytoken' }

    before(:each) do
      expect(app_client).to receive(:create_app_installation_access_token).with('123123').and_return(token: token)
    end

    it "returns an Octokit Client" do
      expect(subject.client).to be_a(Octokit::Client)
    end
  end

  describe 'verify_webhook_signature' do
    before(:each) do
      expect(request).to receive(:env).and_return({ RoctoCop::GithubApp::GITHUB_SIGNATURE_HEADER => digest })
    end

    describe 'with matching digest' do
      let(:digest) { "sha1=#{OpenSSL::HMAC.hexdigest('sha1', RoctoCop::GithubApp::WEBHOOK_SECRET, body)}" }

      it 'it returns true' do
        expect(subject).to_not receive(:halt)
        expect(subject.verify_webhook_signature).to be_truthy
      end
    end

    describe 'with mismatched digest' do
      let(:digest) { "sha1=blahbalh" }

      it 'halts with 401' do
        expect(subject).to receive(:halt).with(401)
        subject.verify_webhook_signature
      end
    end
  end
end
