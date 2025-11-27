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
        $stderr.puts "Failed to update: #{e.message}"
        exit(1)
      end

      # Compare local and remote versions and update if necessary
      # @param local_version [String] The currently installed version
      # @param remote_version [String] The latest version available
      def compare_and_update_versions(local_version, remote_version)
        if Gem::Version.new(remote_version) > Gem::Version.new(local_version)
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
        print 'Do you want to update psdk-cli? [Y/n] '
        response = $stdin.gets.chomp
        return unless response.empty? || response.casecmp('y').zero?

        puts 'Updating psdk-cli...'
        result = system('gem install psdk-cli')
        raise 'gem install psdk-cli failed' unless result

        puts 'Update complete.'
        exit
      end
    end
  end
end
