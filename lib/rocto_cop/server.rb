# frozen_string_literal: true

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

    get '/is_alive' do
      200
    end
  end
end
