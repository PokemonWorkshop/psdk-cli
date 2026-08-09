# frozen_string_literal: true

require 'thor'

module Psdk
  module Cli
    # Class responsible of handling the psdk-use cli commands
    class Use < Thor
      package_name 'psdk-use'

      desc 'studio [--delete]', 'make the project use Pokemon Studio PSDK version.'
      method_option :delete, type: :boolean, aliases: '--delete',
                             desc: 'delete local pokemonsdk folder'
      def studio
        ensure_project
        require_relative '../helpers/psdk'
        PSDK.unuse_local_pokemonsdk(delete: options[:delete])
      end

      desc 'version [PSDK_VERSION]', 'make the project use a specific PSDK version'
      def version(psdk_version)
        ensure_project
        require_relative '../helpers/psdk'
        PSDK.use_version(psdk_version)
      end

      desc 'commit [SHA1]', 'make the project use a specific PSDK commit'
      def commit(sha1)
        ensure_project
        require_relative '../helpers/psdk'
        PSDK.use_commit(sha1)
      end

      desc 'mr [ID]', 'make the project use a specific MR'
      def mr(id)
        ensure_project
        require_relative '../helpers/psdk'
        PSDK.use_mr(id)
      end

      desc 'latest', 'make the project use the latest PSDK commit from development'
      def latest
        ensure_project
        require_relative '../helpers/psdk'
        PSDK.use_latest
      end

      private

      def ensure_project
        require_relative 'configuration'
        Configuration.get(:local)
        return if Configuration.project_path

        $stderr.puts 'Not in a project'
        exit(1)
      end
    end
  end
end
