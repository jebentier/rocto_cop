# frozen_string_literal: true

require_relative '../../spec_helper'

RSpec.describe RoctoCop::Server do
  def app
    RoctoCop::Server
  end

  describe "GET /is_alive" do
    before(:each) { get "/is_alive" }

    it "returns 200 status code" do
      expect(last_response.status).to eq(200)
    end
  end

  describe "POST /event_handler" do
    let(:payload) { {}.to_json }
    let(:headers) { {} }
    before(:each) {
      stub_const('RoctoCop::GithubApp::PRIVATE_KEY', OpenSSL::PKey::RSA.generate(2048))
      stub_const('RoctoCop::GithubApp::APP_IDENTIFIER', '123456')
      stub_const('RoctoCop::GithubApp::WEBHOOK_SECRET', 'thisisasecret')

      allow_any_instance_of(Octokit::Client).to(
        receive(:create_app_installation_access_token).with(anything).and_return(token: 12323445)
      )

      post '/event_handler', payload, { 'CONTENT_TYPE' => 'application/json' }.merge(headers)
    }

    describe 'with an invalid signature' do
      let(:headers) { { RoctoCop::GithubApp::GITHUB_SIGNATURE_HEADER => 'sha1=badsignature' } }

      it 'halts with 401' do
        expect(last_response.status).to eq(401)
      end
    end

    describe 'with a valid signature' do
      describe 'without a repository name in the payload' do
        let(:payload) { { installation: { id: 123456 } }.to_json }
        let(:headers) do
          {
            RoctoCop::GithubApp::GITHUB_SIGNATURE_HEADER =>
              "sha1=#{OpenSSL::HMAC.hexdigest('sha1', RoctoCop::GithubApp::WEBHOOK_SECRET, { installation: { id: 123456 } }.to_json)}"
          }
        end

        it 'responds with a 400' do
          expect(last_response.status).to eq(400)
        end
      end

      describe 'with a repository name in the payload' do
        let(:payload) do
          {
            installation: { id: 123456 },
            repository: { name: 'hello_world' }
          }.to_json
        end

        let(:headers) do
          payload = {
            installation: { id: 123456 },
            repository: { name: 'hello_world' }
          }.to_json

          {
            RoctoCop::GithubApp::GITHUB_SIGNATURE_HEADER =>
              "sha1=#{OpenSSL::HMAC.hexdigest('sha1', RoctoCop::GithubApp::WEBHOOK_SECRET, payload)}"
          }
        end

        it 'responds with 200' do
          expect(last_response.status).to eq(200)
        end
      end
    end
  end
end
