# frozen_string_literal: true

require 'active_support/all'

# RoctoCop module
module RoctoCop; end

require_relative 'rocto_cop/version'
require_relative 'rocto_cop/github_app'

require_relative 'rocto_cop/helpers/app_client'
require_relative 'rocto_cop/helpers/request'

require_relative 'rocto_cop/server'
