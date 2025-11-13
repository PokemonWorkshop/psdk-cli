# frozen_string_literal: true

require 'yaml'

module Psdk
  module Cli
    # Class holding the configuration of the Cli
    class Configuration
      # Filename of the project configuration
      PROJECT_CONFIGURATION_FILENAME = '.psdk-cli.yml'

      # Filename of the global configuration
      GLOBAL_CONFIGURATION_FILENAME = File.join(Dir.home || ENV['USERPROFILE'] || '~', '.psdk-cli/config.yml')

      # Create a new configuration
      # @param hash [Hash] configuration hash
      def initialize(hash)
        hash = {} unless hash.is_a?(Hash)
        # @type [String]
        @studio_path = ''
        # @type [Array<String>]
        @project_paths = []

        self.studio_path = hash[:studio_path] if hash.key?(:studio_path)
        self.project_paths = hash[:project_paths] if hash.key?(:project_paths)
      end

      # Get the Pokémon Studio path
      # @return [String]
      attr_reader :studio_path

      # Set the Pokémon Studio path
      # @param path [String]
      def studio_path=(path)
        unless Dir.exist?(path) || path.empty?
          puts "[Error] Invalid studio_path at `#{path}`, this path does not exists"
          return
        end
        # TODO: add check for locating psdk-binaries
        @studio_path = path
      end

      # Get the project paths
      # @return [Array<String>]
      attr_reader :project_paths

      # Set the project_paths
      # @param paths [Array<String>]
      def project_paths=(paths)
        unless paths.is_a?(Array)
          puts '[Error] project_paths is not an array'
          return
        end
        unless paths.all? { |path| path.is_a?(String) }
          puts '[Error] some of the project paths are not path'
          return
        end

        @project_paths = paths
      end

      def to_h
        return {
          studio_path: @studio_path,
          project_paths: @project_paths
        }
      end

      class << self
        @global = nil
        @local = nil

        # Get the project path
        # @return [String | nil]
        attr_reader :project_path

        # Get the configuration
        # @param type [:global | :local]
        # @return [Configuration]
        def get(type)
          @global ||= Configuration.new(load_hash(GLOBAL_CONFIGURATION_FILENAME))
          return @global if type == :global

          project_path = find_project_path
          @local = nil if @project_path != project_path
          @project_path = project_path
          @local ||= Configuration.new(
            @global.to_h.merge(load_hash(File.join(*@project_path, PROJECT_CONFIGURATION_FILENAME)))
          )

          return @local
        end

        # Save the configuration
        def save
          File.write(GLOBAL_CONFIGURATION_FILENAME, YAML.dump(@global.to_h))
          return unless @local && @project_path

          local_configuration = @local.to_h
          # Delete global configuration keys
          local_configuration.delete(:project_paths)

          File.write(File.join(@project_path, PROJECT_CONFIGURATION_FILENAME), YAML.dump(local_configuration))
        end

        private

        def load_hash(path)
          return {} unless File.exist?(path)

          return YAML.load_file(path, symbolize_names: true, freeze: true)
        rescue StandardError => e
          puts "[Error] failed to load configuration (#{e.message})"
          puts e.backtrace
          return {}
        end

        # Get the project path
        # @return [String | nil]
        def find_project_path
          current_path = Dir.pwd.gsub('\\', '/').split('/')
          all_options = current_path.size.downto(2).map { |i| File.join(*current_path[0...i]) }
          return all_options.find { |path| File.exist?(File.join(path, 'project.studio')) }
        end
      end
    end
  end
end
