# frozen_string_literal: true

require_relative '../cli/configuration'
require_relative 'studio'

module Psdk
  module Cli
    # Module holding all the logic about the version command
    module Version
      module_function

      # Run the version command
      # @param no_psdk_version [Boolean] do not show PSDK version if true
      def run(no_psdk_version)
        puts "psdk-cli v#{VERSION}"
        return if no_psdk_version

        print 'Searching for PSDK version...'
        search_and_show_psdk_version
      end

      # Search and show the PSDK version
      def search_and_show_psdk_version
        search_and_show_global_psdk_version
        search_and_show_local_psdk_version
      end

      # Search and show the global PSDK version
      def search_and_show_global_psdk_version
        global_config = Configuration.get(:global)
        Studio.find_and_save_path if global_config.studio_path.empty?
        psdk_binaries_path = Studio.psdk_binaries_path(global_config.studio_path)
        return show_global_psdk_version(psdk_binaries_path) if psdk_binaries_path

        puts "\r[Error] Current Pokemon Studio path does not contain psdk-binaries"
        global_config.studio_path = ''
        raise ArgumentError
      rescue ArgumentError
        retry
      end

      # Show the global PSDK version
      # @param psdk_binaries_path [String]
      def show_global_psdk_version(psdk_binaries_path)
        version_string = version_to_string(load_version_integer(File.join(psdk_binaries_path, 'pokemonsdk')))
        puts "\rGlobal PSDK version: #{version_string}       "
      end

      # Search and show the local PSDK version
      def search_and_show_local_psdk_version
        Configuration.get(:local)
        return unless Configuration.project_path

        psdk_path = File.join(Configuration.project_path, 'pokemonsdk')
        return show_no_local_psdk_version unless Dir.exist?(psdk_path)

        version_string = version_to_string(load_version_integer(psdk_path))
        puts "Project PSDK version: #{version_string}"
        git_data = load_git_data(psdk_path)
        puts "Project's PSDK git target: #{git_data}" unless git_data.empty?
      end

      # Show that there's no local PSDK version
      def show_no_local_psdk_version
        puts "Project PSDK Version: Studio's PSDK version"
      end

      # Load the Git data if any
      # @param path [String] path to the PSDK installation
      # @return [String]
      def load_git_data(path)
        Dir.chdir(path) do
          return '' unless Dir.exist?('.git') || Dir.exist?('../.git')

          commit = `git log --oneline -n 1`
          branch = `git branch --show-current`
          return "[#{branch}] #{commit}" unless branch.empty?

          return "[!detached] #{commit}"
        end
      end

      # Convert a version integer to a version string
      # @param version [Integer]
      # @return [String]
      def version_to_string(version)
        return [version].pack('I>').unpack('C*').join('.').gsub(/^(0\.)+/, '')
      end

      # Get the version integer from a path
      # @param path [String] path where PSDK repository is
      # @return [Integer]
      def load_version_integer(path)
        filename = File.join(path, 'version.txt')
        return 0 unless File.exist?(filename)

        return File.read(filename).to_i
      end
    end
  end
end
