# frozen_string_literal: true

module RoctoCop
  module Checks
    class << self
      def all
        @all ||= Dir.glob(File.expand_path("./checks/*.rb", __dir__)).map do |file|
          "RoctoCop::Checks::#{file.split('/').last.gsub('.rb', '').camelize}::CHECK_NAME".constantize
        end
      end
    end
  end
end
