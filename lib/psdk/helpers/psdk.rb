# frozen_string_literal: true

require_relative '../cli/configuration'
require 'fileutils'

module Psdk
  module Cli
    # Module holding all the utility to interact with PSDK repository
    module PSDK
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
    end
  end
end
