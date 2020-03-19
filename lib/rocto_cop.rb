# frozen_string_literal: true

require 'active_support/all'

# RoctoCop module
module RoctoCop; end

require_relative 'rocto_cop/version'
require_relative 'rocto_cop/github_app'

require_relative 'rocto_cop/actions'
require_relative 'rocto_cop/actions/linter/fix_all'

require_relative 'rocto_cop/events/check_suite'
require_relative 'rocto_cop/events/check_run'

require_relative 'rocto_cop/checks'
require_relative 'rocto_cop/checks/linter'
require_relative 'rocto_cop/checks/rspec'

require_relative 'rocto_cop/helpers/app_client'
require_relative 'rocto_cop/helpers/request'

require_relative 'rocto_cop/server'
