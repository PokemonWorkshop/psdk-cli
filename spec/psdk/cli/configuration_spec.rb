# frozen_string_literal: true

# rubocop:disable Metrics/BlockLength
RSpec.describe Psdk::Cli::Configuration do
  before(:example) do
    Psdk::Cli::Configuration.instance_eval do
      @global = nil
      @local = nil
    end
  end

  it 'uses home for the global configuration path' do
    # TODO: Fix for Windows if necessary
    expect(Psdk::Cli::Configuration::GLOBAL_CONFIGURATION_FILENAME).to start_with(Dir.home)
    expect(Psdk::Cli::Configuration::GLOBAL_CONFIGURATION_FILENAME).to end_with('/.psdk-cli/config.yml')
  end

  it 'loads configuration with empty hash' do
    config = Psdk::Cli::Configuration.new({})

    expect(config.studio_path).to eq('')
    expect(config.project_paths).to eq([])
    expect(config.to_h).to eq({
                                studio_path: '',
                                project_paths: []
                              })
  end

  it 'does not update invalid path for studio_path' do
    config = Psdk::Cli::Configuration.new({})

    expect(config).to receive(:puts).with(
      '[Error] Invalid studio_path at `/dev/null/cannot_exist`, this path does not exists'
    ).exactly(1).time
    config.studio_path = '/dev/null/cannot_exist'
    expect(config.studio_path).to eq('')
  end

  it 'updates studio_path' do
    config = Psdk::Cli::Configuration.new({})

    allow(Dir).to receive(:exist?) { |filename| filename == 'tmp/studio' }
    config.studio_path = 'tmp/studio'
    expect(config.studio_path).to eq('tmp/studio')
  end

  it 'does not update project_paths if it is not a valid array' do
    config = Psdk::Cli::Configuration.new({})

    expect(config).to receive(:puts).with(
      '[Error] project_paths is not an array'
    ).exactly(1).time
    config.project_paths = '/dev/null/cannot_exist'
    expect(config.project_paths).to eq([])
  end

  it 'does not update project_paths if it contains a non string value' do
    config = Psdk::Cli::Configuration.new({})

    expect(config).to receive(:puts).with(
      '[Error] some of the project paths are not path'
    ).exactly(1).time
    config.project_paths = ['/dev/null/cannot_exist', 0]
    expect(config.project_paths).to eq([])
  end

  it 'update project_paths' do
    config = Psdk::Cli::Configuration.new({})

    config.project_paths = ['tmp/project']
    expect(config.project_paths).to eq(['tmp/project'])
  end

  it 'loads an empty configuration if neither global or local file exists' do
    expect(File).to receive(:read).exactly(0).times
    allow(File).to receive(:exist?).and_return(false)

    global = Psdk::Cli::Configuration.get(:global)
    local = Psdk::Cli::Configuration.get(:local)

    expect(global.to_h).to eq(local.to_h)
    expect(global.studio_path).to eq('')
    expect(global.project_paths).to eq([])
    expect(global.to_h).to eq({
                                studio_path: '',
                                project_paths: []
                              })
  end

  it 'loads global configuration and merge it to local' do
    stub_const('Psdk::Cli::Configuration::GLOBAL_CONFIGURATION_FILENAME', 'tmp/global.yml')
    allow(Dir).to receive(:exist?) { |filename| filename == 'tmp/studio' }
    allow(File).to receive(:exist?) { |filename| filename == 'tmp/global.yml' }
    allow(IO).to receive(:open) do |_, &block|
      block.call(StringIO.new(YAML.dump({ studio_path: 'tmp/studio', project_paths: ['project_a'] })))
    end

    global = Psdk::Cli::Configuration.get(:global)
    local = Psdk::Cli::Configuration.get(:local)
    expect(global.to_h).to eq(local.to_h)
    expect(global).to_not eq(local)
    expect(global.to_h).to eq({
                                studio_path: 'tmp/studio',
                                project_paths: ['project_a']
                              })
    expect(Psdk::Cli::Configuration.project_path).to eq(nil)
  end

  it 'loads global configuration and merge it to local while preserving local defined values' do
    stub_const('Psdk::Cli::Configuration::GLOBAL_CONFIGURATION_FILENAME', 'tmp/global.yml')
    allow(Dir).to receive(:exist?) { |filename| filename.start_with?('tmp/') }
    allow(File).to receive(:exist?) { |filename| filename.end_with?('/project.studio') || filename.end_with?('.yml') }
    allow(IO).to receive(:open) do |filename, &block|
      if filename == 'tmp/global.yml'
        block.call(StringIO.new(YAML.dump({ studio_path: 'tmp/studio', project_paths: ['project_a'] })))
      else
        block.call(StringIO.new(YAML.dump({ studio_path: 'tmp/studio_repository' })))
      end
    end

    global = Psdk::Cli::Configuration.get(:global)
    local = Psdk::Cli::Configuration.get(:local)
    expect(global.to_h).to eq({
                                studio_path: 'tmp/studio',
                                project_paths: ['project_a']
                              })
    expect(local.to_h).to eq({
                               studio_path: 'tmp/studio_repository',
                               project_paths: ['project_a']
                             })
    expect(Psdk::Cli::Configuration.project_path).to eq(Dir.pwd)
  end

  it 'successfully saves the configurations' do
    stub_const('Psdk::Cli::Configuration::GLOBAL_CONFIGURATION_FILENAME', 'tmp/global.yml')
    allow(File).to receive(:exist?) { |filename| filename.end_with?('/project.studio') }
    allow(Dir).to receive(:exist?) { |filename| filename.start_with?('tmp/') || filename.end_with?('tmp') }

    global = Psdk::Cli::Configuration.get(:global)
    local = Psdk::Cli::Configuration.get(:local)

    global.studio_path = 'tmp/studio'
    local.studio_path = 'tmp/project'
    local.project_paths = %w[a b c] # Never saved

    expect(File).to receive(:write).with('tmp/global.yml',
                                         "---\n:studio_path: tmp/studio\n:project_paths: []\n")
    expect(File).to receive(:write).with(File.join(Dir.pwd, '.psdk-cli.yml'),
                                         "---\n:studio_path: tmp/project\n")
    Psdk::Cli::Configuration.save
  end

  it 'loads the project path as the path that contains project.studio' do
    allow(Dir).to receive(:pwd) { '/users/user_a/documents/projects/super_game/Data/studio/maps' }
    allow(Dir).to receive(:exist?) { |filename| filename == 'tmp/studio_repository' }
    allow(File).to receive(:exist?) do |filename|
      next filename.end_with?('/super_game/project.studio') || filename.end_with?('/.psdk-cli.yml')
    end
    allow(IO).to receive(:open) do |_, &block|
      block.call(StringIO.new(YAML.dump({ studio_path: 'tmp/studio_repository' })))
    end

    local = Psdk::Cli::Configuration.get(:local)
    expect(local.to_h).to eq({ studio_path: 'tmp/studio_repository', project_paths: [] })
    expect(Psdk::Cli::Configuration.project_path).to eq('/users/user_a/documents/projects/super_game')
  end
end
# rubocop:enable Metrics/BlockLength
