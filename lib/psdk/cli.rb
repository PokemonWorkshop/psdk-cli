# frozen_string_literal: true

require 'thor'

module Psdk
  module Cli
    # Main PSDK CLI class
    #
    # Must be used for the general psdk-cli command
    class Main < Thor
      package_name 'psdk-cli'

      desc('version', 'show the psdk-cli version')
      def version
        puts "psdk-cli v#{VERSION}"
      end
    end
  end
end

require_relative 'cli/version'
