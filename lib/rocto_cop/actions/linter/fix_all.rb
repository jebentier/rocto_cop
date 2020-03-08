# frozen_string_literal: true

module RoctoCop
  module Actions
    module Linter
      class FixAll
        class << self
          def action_definition
            {
              label: 'Fix all these',
              description: 'Fix all Roctocop Linter notices for me.',
              identifier: 'fix_roctocop_linter'
            }
          end
        end
      end
    end
  end
end
