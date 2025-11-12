# frozen_string_literal: true

require 'thor'

module Psdk
  module Cli
    # Class responsible of handling the psdk-plugin cli commands
    class Plugin < Thor
      package_name 'psdk-plugin'

      # TODO: remove this and actually implement the plugin cli
      desc 'fake ARG1', 'run a fake command with ARG1 as first argument'
      def fake(arg1)
        puts "Fake called with ARG1=#{arg1}"
      end
    end
  end
end
