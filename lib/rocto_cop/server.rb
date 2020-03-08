# frozen_string_literal: true

require 'active_support/all'
require 'sinatra'
require 'logger'

set :port, 3000
set :bind, '0.0.0.0'

module RoctoCop
  class Server < Sinatra::Application
    # In development mode set the logging to debug mode
    configure :development do
      set :logging, Logger::DEBUG
    end

    helpers RoctoCop::Helpers::AppClient
    helpers RoctoCop::Helpers::Request

    before '/event_handler' do
      payload
      verify_webhook_signature

      logger.debug "---- received event #{request.env[RoctoCop::GithubApp::GITHUB_ACTION_HEADER]}"
      logger.debug "----  action: #{payload['action'].inspect}"

      repository_name = payload.dig('repository', 'name') || ""
      (repository_name =~ /[0-9A-Za-z\-\_]+/).present? or halt 400

      logger.debug "----  repository: #{repository_name}"

      app_client
      client
    end

    get '/is_alive' do
      200
    end

    post '/event_handler' do
      request.env[RoctoCop::GithubApp::GITHUB_EVENT_HEADER].tap do |event|
        logger.debug "----  event: #{event}"

        case request.env[RoctoCop::GithubApp::GITHUB_EVENT_HEADER]
        when 'check_suite' then RoctoCop::Events::CheckSuite.new(payload).process(client)
        when 'check_run'   then RoctoCop::Events::CheckRun.new(payload).process(client)
        else logger.debug "----  Unknown event"
        end
      end

      200
    end
  end
end
