# frozen_string_literal: true

module Psdk
  module Helpers
    module PluginManager
      # Module handling the listing of plugins
      module List
        # Folder containing scripts
        SCRIPTS_FOLDER = 'scripts'
        # File containing plugin information
        PLUGIN_INFO_FILE = "#{SCRIPTS_FOLDER}/plugins.dat".freeze

        class << self
          # List all the plugins
          def list_plugins
            plugins = load_existing_plugins
            show_splash(' List of your plugins')
            if plugins.empty?
              puts 'No plugins installed.'
              return
            end

            plugins.each do |plugin|
              puts "- \e[34m#{plugin.name}\e[36m v#{plugin.version}\e[0m"
              puts "  authors: #{plugin.authors.join(', ')}"
            end
          end

          private

          # Load the plugins that are already installed
          # @return [Array<Psdk::Helpers::PluginManager::Config>]
          def load_existing_plugins
            return File.exist?(PLUGIN_INFO_FILE) ? Marshal.load(File.binread(PLUGIN_INFO_FILE)) : [] # rubocop:disable Security/MarshalLoad
          rescue StandardError => e
            puts "Failed to load plugins.dat: #{e.message}"
            []
          end

          # Show the plugin manager splash
          # @param reason [String] reason to show the splash
          def show_splash(reason = ' Something changed in your plugins! ')
            sep = ''.center(80, '=')
            puts "\e[32m#{sep}\e[0m"
            puts "\e[32m##{' PSDK Plugin Manager v1.0 '.center(78, ' ')}#\e[0m"
            puts "\e[32m##{reason.ljust(78, ' ')}#\e[0m"
            puts "\e[32m#{sep}\e[0m"
          end
        end
      end
    end
  end
end
