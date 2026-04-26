# frozen_string_literal: true

require 'thor'

module Psdk
  module Cli
    # Class responsible of handling the psdk-plugin cli commands
    class Plugin < Thor
      package_name 'psdk-plugin'

      desc 'list', 'List all installed plugins in the current PSDK project'
      def list
        require_relative '../helpers/plugin_manager'

        unless Psdk::Cli::Configuration.get(:local)&.project_path
          puts 'Error: You must be inside a PSDK project to use `psdk-plugin list`.'
          exit(1)
        end

        Psdk::Helpers::PluginManager.list
      end

      desc 'build [PLUGIN_NAME]', 'Build a plugin (requires to be at the root of the project or the plugin)'
      option :no_psdk_project, type: :boolean, desc: 'Force standalone mode (build outside a PSDK project)'
      option :out_dir, type: :string, default: '.', desc: 'Output directory for the generated .psdkplug file'
      def build(plugin_name = nil)
        require_relative '../helpers/plugin_manager'

        in_project = Psdk::Cli::Configuration.get(:local)&.project_path
        in_project = false if options[:no_psdk_project]

        plugin_name = '.' if !in_project && plugin_name.nil?

        unless plugin_name
          puts 'Error: You must provide a plugin_name when building inside a PSDK project.'
          exit(1)
        end

        Psdk::Helpers::PluginManager.build(plugin_name, in_project: in_project, out_dir: options[:out_dir])
      end
    end
  end
end
