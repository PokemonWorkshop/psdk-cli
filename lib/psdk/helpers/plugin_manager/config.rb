# frozen_string_literal: true

module Psdk
  module Helpers
    module PluginManager
      # Plugin configuration
      class Config
        # Get the plugin name
        # @return [String]
        attr_accessor :name
        # Get the plugin authors
        # @return [Array<String>]
        attr_accessor :authors
        # Get the version of the plugin
        # @return [String]
        attr_accessor :version
        # Get the dependecies or incompatibilities of the plugin
        # @return [Array<Hash>]
        attr_accessor :deps
        # Get the script that tests if PSDK is compatible with this plugin
        # @return [String, nil]
        attr_accessor :psdk_compatibility_script
        # Tell if the psdk_compatibility_script should be executed after all plugins has been loaded
        # @return [Boolean, nil]
        attr_accessor :retry_psdk_compatibility_after_plugin_load
        # Get the script that tests if the plugin is compatible with other plugins
        # @return [String, nil]
        attr_accessor :additional_compatibility_script
        # Get all the files added by the plugin (in order to compile the plugin / remove files)
        # @return [Array<String>]
        attr_accessor :added_files
        # Get the SHA512 of the plugin (computed after it got compiled)
        # @return [String]
        attr_accessor :sha512
        # Get the PSDK version the plugin was installed
        # @return [Integer]
        attr_accessor :psdk_version
      end
    end
  end
end

PluginManager = Psdk::Helpers::PluginManager
