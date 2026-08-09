# frozen_string_literal: true

require_relative '../cli/configuration'
require 'fileutils'

module Psdk
  module Cli
    # Module holding all the utility to interact with PSDK repository
    module PSDK # rubocop:disable Metrics/ModuleLength
      # Default URL to the PSDK repository
      MAIN_REPOSITORY_URL = 'https://gitlab.com/pokemonsdk/pokemonsdk.git'

      module_function

      # Ensure the PSDK module is cloned
      def ensure_repository_cloned
        return if Dir.exist?(File.join(repository_path, '.git'))

        res = system('git', 'clone', MAIN_REPOSITORY_URL, chdir: Configuration::PATH)
        return if res

        puts "[Error] Failed to setup pokemonsdk repository in `#{Configuration::PATH}`"
        exit(1)
      end

      # Get the repository path
      # @return [String]
      def repository_path
        return File.join(Configuration::PATH, 'pokemonsdk')
      end

      # Make the project use an official PSDK release
      # @param version [String] release identifier (e.g., "26.58")
      def use_version(version)
        switch_project_repository("official release #{version}") do |path|
          fetch_repository(path)
          commit = run_git(path, 'log', '--format=%H', '--extended-regexp',
                           "--grep=^Release #{Regexp.escape(version)}$", '--max-count=1', 'origin/release')
          raise "PSDK release #{version} was not found" if commit.empty?

          run_git(path, 'checkout', '--detach', commit)
        end
      end

      # Make the project use a specific PSDK commit
      # @param commit [String] commit identifier (e.g., "deadcafe")
      def use_commit(commit)
        switch_project_repository("commit #{commit}") do |path|
          fetch_repository(path)
          resolved_commit = run_git(path, 'rev-parse', '--verify', '--end-of-options', "#{commit}^{commit}")
          run_git(path, 'checkout', '--detach', resolved_commit)
        end
      end

      # Make the project use the head of a GitLab merge request
      # @param id [String] merge request ID (e.g., "123")
      def use_mr(id)
        switch_project_repository("merge request !#{id}") do |path|
          ref = "refs/remotes/origin/merge-requests/#{id}"
          run_git(path, 'fetch', 'origin', "+refs/merge-requests/#{id}/head:#{ref}")
          run_git(path, 'checkout', '-B', "mr-#{id}", ref)
        end
      end

      # Make the project use the latest development commit
      def use_latest
        switch_project_repository('latest development commit') do |path|
          fetch_repository(path)
          run_git(path, 'checkout', '-B', 'development', 'origin/development')
        end
      end

      # Unuse the local pokemonsdk folder (meaning we want the project to fallback on Pokémon Studio's PSDK)
      # @param delete [Boolean] if the folder should be deleted
      def unuse_local_pokemonsdk(delete:)
        project_path = Configuration.project_path
        psdk_path = File.join(project_path, 'pokemonsdk')
        return unless Dir.exist?(psdk_path)

        if git_project?(project_path) && submodule?(project_path)
          remove_submodule(project_path, delete)
        else
          handle_non_submodule_folder(psdk_path, delete)
        end
      ensure
        puts "Successfully set project to use Pokémon Studio's PSDK version"
      end

      # Handle the pokemonsdk folder when it's not a submodule
      # @param psdk_path [String] the path to the pokemonsdk folder
      # @param delete [Boolean] if the folder should be deleted
      def handle_non_submodule_folder(psdk_path, delete)
        if delete
          FileUtils.rm_rf(psdk_path)
        else
          rename_pokemonsdk_folder(psdk_path)
        end
      end

      # Check if the project is a git project
      # @param project_path [String] the path to the project
      # @return [Boolean]
      def git_project?(project_path)
        return File.exist?(File.join(project_path, '.git'))
      end

      # Check if the project is a submodule
      # @param project_path [String] the path to the project
      # @return [Boolean]
      def submodule?(project_path)
        return system('git', 'submodule', 'status', 'pokemonsdk', chdir: project_path, out: File::NULL, err: File::NULL)
      end

      # Remove the submodule
      # @param project_path [String] the path to the project
      # @param delete [Boolean] if the folder should be deleted
      def remove_submodule(project_path, delete)
        return show_remove_submodule_delete_error unless delete

        r = system('git', 'submodule', 'deinit', '-f', 'pokemonsdk', chdir: project_path, out: File::NULL, err: File::NULL)
        raise 'Failed to deinit pokemonsdk submodule' unless r

        r = system('git', 'rm', '-f', 'pokemonsdk', chdir: project_path, out: File::NULL, err: File::NULL)
        raise 'Failed to remove pokemonsdk submodule' unless r

        FileUtils.rm_rf(File.join(project_path, '.git', 'modules', 'pokemonsdk'))
        puts 'Successfully removed the submodule'
      rescue StandardError => e
        puts "[Error] Failed to remove the submodule (#{e.message})"
        exit(1)
      end

      # Show the error message when attempting to delete the pokemonsdk submodule
      def show_remove_submodule_delete_error
        puts "[Error] Cannot use Studio's PSDK version if the project has a submodule."
        puts 'Please follow this guide to remove the submodule: https://stackoverflow.com/a/1260982'
        exit(1)
      end

      # Rename the pokemonsdk folder
      # @param psdk_path [String] the path to the pokemonsdk folder
      def rename_pokemonsdk_folder(psdk_path)
        new_path = "#{psdk_path}_old"
        if File.exist?(new_path)
          puts "[Error] Folder `#{new_path}` already exists. Please remove it manually."
          exit(1)
        else
          File.rename(psdk_path, new_path)
        end
      end

      # Run a repository switch: resolve the project's pokemonsdk path, apply the given block,
      # then refresh submodules and report the active target
      # @param target [String] human-readable description of the switch target, used in the confirmation message
      # @yieldparam path [String] path to the project's pokemonsdk repository
      def switch_project_repository(target)
        path = ensure_project_repository
        yield(path)
        run_git(path, 'submodule', 'update', '--init', '--recursive')
        show_active_target(path, target)
      rescue StandardError => e
        show_switch_error(e)
      end

      # Ensure the project's pokemonsdk repository exists, cloning it if necessary
      # @return [String] path to the project's pokemonsdk repository
      def ensure_project_repository
        path = File.join(Configuration.project_path, 'pokemonsdk')
        return path if File.exist?(File.join(path, '.git'))

        raise "#{path} exists but is not a Git repository" if Dir.exist?(path)

        success = system('git', 'clone', MAIN_REPOSITORY_URL, path)
        raise "Failed to clone pokemonsdk into `#{path}`" unless success

        return path
      end

      # Fetch the latest refs from origin
      # @param path [String] path to the repository
      def fetch_repository(path)
        run_git(path, 'fetch', 'origin')
      end

      # Run a git command in the given repository and return its output
      # @param path [String] path to the repository
      # @param arguments [Array<String>] git subcommand and its arguments
      # @return [String] the stripped stdout of the command
      def run_git(path, *arguments)
        output = IO.popen(['git', *arguments], chdir: path, &:read)
        return output.strip if $?.success? # rubocop:disable Style/SpecialGlobalVars

        raise "git #{arguments.join(' ')} failed"
      end

      # Show the confirmation message for the currently active PSDK target
      # @param path [String] path to the repository
      # @param target [String] human-readable description of the active target
      def show_active_target(path, target)
        commit = run_git(path, 'rev-parse', '--short', 'HEAD')
        version = File.read(File.join(path, 'version.txt')).to_i
        version_string = [version].pack('I>').unpack('C*').join('.').gsub(/^(0\.)+/, '')
        puts "Active PSDK: #{target} (version #{version_string}, commit #{commit})"
      end

      # Show the error message when a PSDK switch operation fails
      # @param error [StandardError] the error that was raised
      def show_switch_error(error)
        puts "[Error] Failed to switch PSDK: #{error.message}"
        exit(1)
      end
    end
  end
end
