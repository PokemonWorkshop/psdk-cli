# frozen_string_literal: true

require_relative '../cli/version'

module Psdk
  module Cli
    # Module holding the logic to update the psdk-cli gem
    module VersionUpdate
      module_function

      # Check if the psdk-cli gem is up-to-date and update it if needed
      def check_and_update
        puts 'Checking for updates...'
        local_version = Psdk::Cli::VERSION
        remote_version = fetch_remote_version

        compare_and_update_versions(local_version, remote_version)
      rescue StandardError => e
        puts "Failed to check for updates: #{e.message}"
      end

      # Compare local and remote versions and update if necessary
      # @param local_version [String] The currently installed version
      # @param remote_version [String] The latest version available
      def compare_and_update_versions(local_version, remote_version)
        if remote_version > local_version
          puts "New version available: #{remote_version} (current: #{local_version})"
          update_gem
        else
          puts 'psdk-cli is up-to-date.'
        end
      end

      # Fetch the latest version of psdk-cli from rubygems
      # @return [String]
      def fetch_remote_version
        output = `gem search -r psdk-cli`
        match = output.match(/psdk-cli \(([\d.]+)\)/)
        return match[1] if match

        raise 'Could not find psdk-cli in remote gems'
      end

      # Update the psdk-cli gem
      def update_gem
        puts 'Updating psdk-cli...'
        system('gem install psdk-cli')
        puts 'Update complete. Please restart the command.'
        exit
      end
    end
  end
end
