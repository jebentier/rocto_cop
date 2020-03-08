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

    before(:each) do
      allow_any_instance_of(Octokit::Client).to(
        receive(:create_app_installation_access_token).with(anything).and_return(token: 12323445)
      )
    end

    describe 'event validations' do
      before(:each) do
        post '/event_handler', payload, { 'CONTENT_TYPE' => 'application/json' }.merge(headers)
      end

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

    describe 'with an valid unknown event' do
      let(:payload) { load_event(:valid_check_suite_request) }
      let(:headers) do
        {
          RoctoCop::GithubApp::GITHUB_SIGNATURE_HEADER => event_signature(:valid_check_suite_request),
          RoctoCop::GithubApp::GITHUB_EVENT_HEADER     => 'unknown'
        }
      end

      it 'processes the event and returns a 200' do
        post '/event_handler', payload, { 'CONTENT_TYPE' => 'application/json' }.merge(headers)
        expect(last_response.status).to eq(200)
      end
    end

    describe 'with a valid check_suite request event' do
      let(:payload) { load_event(:valid_check_suite_request) }
      let(:headers) do
        {
          RoctoCop::GithubApp::GITHUB_SIGNATURE_HEADER => event_signature(:valid_check_suite_request),
          RoctoCop::GithubApp::GITHUB_EVENT_HEADER     => 'check_suite'
        }
      end

      let(:event)   { double(RoctoCop::Events::CheckSuite) }

      it 'processes the event and returns a 200' do
        expect(RoctoCop::Events::CheckSuite).to receive(:new).with(JSON.parse(payload)).and_return(event)
        expect(event).to receive(:process)

        post '/event_handler', payload, { 'CONTENT_TYPE' => 'application/json' }.merge(headers)

        expect(last_response.status).to eq(200)
      end
    end
  end
end
