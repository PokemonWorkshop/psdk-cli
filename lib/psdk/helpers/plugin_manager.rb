# frozen_string_literal: true

require_relative 'plugin_manager/config'
require_relative 'plugin_manager/list'
require_relative 'plugin_manager/builder'

# Module handling the plugin commands
module PluginManager
  class << self
    # List all the plugins installed in the current PSDK project
    def list
      List.list_plugins
    end

    # Build a plugin
    # @param plugin_name [String] name of the plugin to build
    # @param in_project [Boolean] whether to build using PSDK project structure
    # @param out_dir [String] directory to output the compiled plugin
    def build(plugin_name, in_project: true, out_dir: '.')
      Builder.new(plugin_name, in_project: in_project, out_dir: out_dir).build
    end
  end
end
