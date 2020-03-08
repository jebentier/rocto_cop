# frozen_string_literal: true

module RoctoCop
  module Actions
    class << self
      def run(action_name, client, repository, branch, run_id)
        if (check_class = all[action_name])
          check_class.new(client, repository, branch, run_id).run
        end
      end

      def all
        @all ||= Dir.glob(File.expand_path("./actions/**/*.rb", __dir__)).to_h do |file|
          relevant_file      = file.split('actions/').last.gsub('.rb', '')
          partial_class_name = relevant_file.split('/').map(&:camelize).join('::')
          full_class_name    = "RoctoCop::Actions::#{partial_class_name}"

          ["#{full_class_name}::ACTION_NAME".constantize, full_class_name.constantize]
        end
      end

      def names
        all.keys
      end
    end
  end
end
