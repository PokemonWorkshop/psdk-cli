# frozen_string_literal: true

require 'yaml'
require 'digest'
require_relative '../900 Yuki__VD'

module Psdk
  module Helpers
    module PluginManager
      # Class responsible of building plugins
      class Builder # rubocop:disable Metrics/ClassLength
        PLUGIN_FILE_EXT = 'psdkplug'
        SCRIPTS_FOLDER = 'scripts'

        # Create a new plugin builder
        # @param plugin_name [String] name of the plugin directory
        # @param in_project [Boolean] whether we are building inside a PSDK project
        # @param out_dir [String] directory to output the compiled plugin
        def initialize(plugin_name, in_project: true, out_dir: '.')
          @name = plugin_name
          @in_project = in_project
          @out_dir = out_dir
        end

        # Start the building process
        def build # rubocop:disable Metrics/AbcSize,Metrics/MethodLength
          puts "--- Starting build for plugin '#{@name}' ---"
          if @in_project
            puts '[INFO] Operating inside a PSDK project.'
          else
            puts '[INFO] Operating in standalone mode (outside a PSDK project).'
          end

          @config = load_plugin_configuration
          plugin_filename = File.join(@out_dir, "#{@config.name}.#{PLUGIN_FILE_EXT}")
          tmp_filename = "#{plugin_filename}.tmp"

          puts "Creating temporary plugin file: #{tmp_filename}"
          @yuki_vd = Yuki::VD.new(tmp_filename, :write)

          add_scripts
          add_files
          add_testers

          @yuki_vd.close

          puts 'Computing SHA512 of the generated package...'
          filesize = File.binread(tmp_filename, Yuki::VD::POINTER_SIZE).unpack1(Yuki::VD::UNPACK_METHOD) - Yuki::VD::POINTER_SIZE
          filedata = File.binread(tmp_filename, filesize, Yuki::VD::POINTER_SIZE)
          @config.sha512 = Digest::SHA512.hexdigest(filedata)

          puts 'Writing final configuration with SHA512 to package...'
          @yuki_vd = Yuki::VD.new(tmp_filename, :update)
          @yuki_vd.write_data("\x00", Marshal.dump(@config))
          @yuki_vd.close

          File.rename(tmp_filename, plugin_filename)
          puts "\e[32m[SUCCESS]\e[0m Built #{@config.name} at #{plugin_filename}"
        end

        private

        # Return the base directory of the plugin source code
        def base_dir
          if @in_project
            File.join(SCRIPTS_FOLDER, @name)
          else
            @name == '.' ? '.' : @name
          end
        end

        # Return the directory name used for scripts relative to base_dir
        def script_src_dir
          # Inside a project, scripts are often in `scripts/{plugin_name}/scripts/**/*.rb`
          # Outside, it's `scripts/**/*.rb`
          # In both cases, the folder is `scripts` relative to base_dir (or `script` according to some docs, we check both or use 'scripts') # rubocop:disable Layout/LineLength
          return 'scripts'
        end

        # Function that adds all the scripts for the plugin
        def add_scripts # rubocop:disable Metrics/MethodLength
          b_dir = base_dir
          b_dir_prefix = b_dir == '.' ? '' : "#{b_dir}/"

          search_path = File.join(b_dir, script_src_dir, '**', '*.rb')
          search_path = search_path.sub(%r{^/}, '') if search_path.start_with?('/')

          scripts = Dir[search_path]

          puts "Found #{scripts.size} ruby scripts to pack."
          scripts.each do |filename|
            script = File.read(filename)
            internal_path = filename.sub(b_dir_prefix, '')
            puts "  - Packing script: #{filename} -> #{internal_path}"
            @yuki_vd.write_data(internal_path, script)
          end
        end

        # Function that add all the files for the plugin
        def add_files
          project_root = @in_project.is_a?(String) ? @in_project : Dir.pwd

          Dir.chdir(project_root) do
            filenames = (@config.added_files || []).flat_map { |dirspec| Dir[dirspec] }.select { |f| File.file?(f) }

            puts "Found #{filenames.size} resource files to pack."
            filenames.each do |filename|
              data = File.binread(filename)
              puts "  - Packing file: #{filename}"
              @yuki_vd.write_data(filename, data)
            end
          end
        end

        # Function that adds the compatibility test script
        def add_testers # rubocop:disable Metrics/AbcSize,Metrics/MethodLength
          b_dir = base_dir
          if @config.psdk_compatibility_script
            tester_path = File.join(b_dir, @config.psdk_compatibility_script)
            if File.exist?(tester_path)
              puts "Adding PSDK compatibility script: #{tester_path}"
              data = File.read(tester_path)
              @yuki_vd.write_data("\x01", data)
            else
              puts "[WARNING] PSDK compatibility script not found: #{tester_path}"
            end
          end
          return unless @config.additional_compatibility_script

          tester_path = File.join(b_dir, @config.additional_compatibility_script)
          if File.exist?(tester_path)
            puts "Adding additional compatibility script: #{tester_path}"
            data = File.read(tester_path)
            @yuki_vd.write_data("\x02", data)
          else
            puts "[WARNING] Additional compatibility script not found: #{tester_path}"
          end
        end

        # Load the plugin configuration
        # @return [Psdk::Helpers::PluginManager::Config]
        def load_plugin_configuration # rubocop:disable Metrics/AbcSize,Metrics/MethodLength
          config_path = File.join(base_dir, 'config.yml')
          raise "Configuration file not found at #{config_path}" unless File.exist?(config_path)

          puts "Loading configuration from #{config_path}"
          yaml_content = YAML.unsafe_load(File.read(config_path))

          # Populate Config object
          config = Psdk::Helpers::PluginManager::Config.new
          config.name = yaml_content['name'] || @name
          config.authors = yaml_content['authors'] || []
          config.version = yaml_content['version'] || '1.0.0'
          config.deps = yaml_content['deps'] || []
          config.psdk_compatibility_script = yaml_content['psdk_compatibility_script']
          config.retry_psdk_compatibility_after_plugin_load = yaml_content['retry_psdk_compatibility_after_plugin_load']
          config.additional_compatibility_script = yaml_content['additional_compatibility_script']
          config.added_files = yaml_content['added_files'] || []

          return config
        end
      end
    end
  end
end
