# frozen_string_literal: true

require 'thor'
require_relative 'cli/version'
require_relative 'cli/plugin'

module Psdk
  module Cli
    # Main PSDK CLI class
    #
    # Must be used for the general psdk-cli command
    class Main < Thor
      package_name 'psdk-cli'

      desc 'version', 'show the psdk-cli version'
      method_option :no_psdk_version, type: :boolean, aliases: '--no-psdk-version',
                                      desc: 'do not search and show PSDK version'
      def version
        require_relative 'helpers/version'
        Version.run(options[:no_psdk_version])
      end

      desc 'plugin', 'manage PSDK plugins'
      subcommand 'plugin', Plugin
    end
  end
end
