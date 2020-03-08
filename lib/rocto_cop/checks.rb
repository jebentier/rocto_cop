# frozen_string_literal: true

module RoctoCop
  module Checks
    class << self
      def run(check_name, client, repository, head_sha, run_id)
        if (check_class = all[check_name])
          check_class.new(client, repository, head_sha, run_id).run
        end
      end

      def all
        @all ||= Dir.glob(File.expand_path("./checks/*.rb", __dir__)).to_h do |file|
          full_class_name = "RoctoCop::Checks::#{file.split('/').last.gsub('.rb', '').camelize}"
          ["#{full_class_name}::CHECK_NAME".constantize, full_class_name.constantize]
        end
      end

      def names
        all.keys
      end
    end
  end
end
