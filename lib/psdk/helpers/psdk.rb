# frozen_string_literal: true

require_relative '../cli/configuration'

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
    end
  end
end
