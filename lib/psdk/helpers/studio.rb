# frozen_string_literal: true

require_relative '../cli/configuration'

module Psdk
  module Cli
    # Module holding all the logic about the Pokémon Studio
    module Studio
      module_function

      # Find and Save Pokemon studio path
      # @param type [:global | :local] where to save the located studio path
      def find_and_save_path(type)
        locations = common_studio_location.select { |l| Dir.exist?(l) }
        binaries_locations = psdk_binaries_locations
        studio_path = locations.find { |l| binaries_locations.any? { |b| Dir.exist?(File.join(l, b)) } }
        unless studio_path
          puts '[Error] failed to locate Pokemon Studio, please set it up manually'
          exit(1)
        end

        puts "Located Pokemon Studio in `#{studio_path}`"
        Configuration.get(type).studio_path = studio_path
        Configuration.save
      end

      # Get the PSDK binary path based on Studio path
      # @param path [String]
      # @return [String | nil]
      def psdk_binaries_path(path)
        valid_path = psdk_binaries_locations.find { |l| Dir.exist?(File.join(path, l)) }
        return nil unless valid_path

        return File.join(path, valid_path)
      end

      # Get all the common Pokemon Studio location
      # @return [Array<String>]
      def common_studio_location
        volumes = Dir['/Volumes/**'] + Dir['/dev/sd*']
        return [
          '/Applications/PokemonStudio.app',
          *(ENV['AppData'] ? studio_app_data_location : nil),
          *volumes.map { |v| File.join(v, 'projects', 'PokemonStudio') },
          'C:/Projects/PokemonStudio'
        ]
      end

      # Get all the psdk-binaries common location in Studio
      # @return [Array<String>]
      def psdk_binaries_locations
        return [
          'psdk-binaries',
          'Contents/Resources/psdk-binaries',
          'resources/psdk-binaries'
        ]
      end

      # Get the location of Studio in appdata
      # @return [String]
      def studio_app_data_location
        return File.join(ENV.fetch('AppData', '.'), '../Local/Programs/pokemon-studio')
      end
    end
  end
end
