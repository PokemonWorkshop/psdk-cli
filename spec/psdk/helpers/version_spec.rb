# frozen_string_literal: true

# rubocop:disable Metrics/BlockLength
RSpec.describe Psdk::Cli::Version do
  it 'only prints the cli version' do
    expect(Psdk::Cli::Version).to receive(:puts).with("psdk-cli v#{Psdk::Cli::VERSION}")
    expect(Psdk::Cli::Version).not_to receive(:print).with('Searching for PSDK version...')
    expect(Psdk::Cli::Version).not_to receive(:search_and_show_global_psdk_version)
    expect(Psdk::Cli::Version).not_to receive(:search_and_show_local_psdk_version)

    Psdk::Cli::Version.run(true)
  end

  it 'search global psdk version' do
    configuration = Psdk::Cli::Configuration.new({})
    expect(Psdk::Cli::Configuration).to receive(:get).with(:global).and_return(configuration)
    expect(Psdk::Cli::Studio).to receive(:find_and_save_path) {
      configuration.instance_variable_set(:@studio_path, '/path')
    }
    expect(Psdk::Cli::Studio).to receive(:psdk_binaries_path).and_return('/path/psdk-binaries')
    expect(Psdk::Cli::Version).to receive(:show_global_psdk_version).with('/path/psdk-binaries')

    Psdk::Cli::Version.search_and_show_global_psdk_version
  end

  it 'shows global version' do
    allow(Dir).to receive(:exist?) { true }
    configuration = Psdk::Cli::Configuration.new({ studio_path: '/path' })
    expect(Psdk::Cli::Configuration).to receive(:get).with(:global).and_return(configuration)
    expect(Psdk::Cli::Studio).to receive(:psdk_binaries_path).and_return('/path/psdk-binaries')
    expect(Psdk::Cli::Version).to receive(:show_global_psdk_version).with('/path/psdk-binaries')

    Psdk::Cli::Version.search_and_show_global_psdk_version
  end

  it 'retry if initial path was invalid' do
    allow(Dir).to receive(:exist?) { true }
    configuration = Psdk::Cli::Configuration.new({ studio_path: '/invalid_path' })
    expect(Psdk::Cli::Configuration).to receive(:get).with(:global).and_return(configuration).exactly(2).times
    allow(Psdk::Cli::Studio).to receive(:psdk_binaries_path) { |path| path == '/invalid_path' ? nil : '/path/psdk-binaries' }
    expect(Psdk::Cli::Version).to receive(:show_global_psdk_version).with('/path/psdk-binaries')
    expect(Psdk::Cli::Studio).to receive(:find_and_save_path) {
      configuration.instance_variable_set(:@studio_path, '/path')
    }
    expect(configuration).to receive(:studio_path=).with('').and_call_original
    expect(Psdk::Cli::Version).to receive(:puts).with(
      "\r[Error] Current Pokemon Studio path does not contain psdk-binaries"
    )

    Psdk::Cli::Version.search_and_show_global_psdk_version
  end

  it 'shows global version' do
    expect(File).to receive(:exist?).with('/path/psdk-binaries/pokemonsdk/version.txt').and_return(true)
    expect(File).to receive(:read).with('/path/psdk-binaries/pokemonsdk/version.txt').and_return('4256')
    expect(Psdk::Cli::Version).to receive(:puts).with("\rGlobal PSDK version: 16.160       ")

    Psdk::Cli::Version.show_global_psdk_version('/path/psdk-binaries')
  end

  it 'shows global version even if version.txt was not found' do
    expect(File).to receive(:exist?).with('/path/psdk-binaries/pokemonsdk/version.txt').and_return(false)
    expect(Psdk::Cli::Version).to receive(:puts).with("\rGlobal PSDK version: 0       ")

    Psdk::Cli::Version.show_global_psdk_version('/path/psdk-binaries')
  end

  it 'do not show local version if no project is configured' do
    configuration = Psdk::Cli::Configuration.new({})
    expect(Psdk::Cli::Configuration).to receive(:get).with(:local).and_return(configuration)
    expect(Psdk::Cli::Configuration).to receive(:project_path).and_return(nil)

    Psdk::Cli::Version.search_and_show_local_psdk_version
  end

  it 'shows "studio\'s version" if no local pokemonsdk folder exists' do
    configuration = Psdk::Cli::Configuration.new({})
    expect(Psdk::Cli::Configuration).to receive(:get).with(:local).and_return(configuration)
    allow(Psdk::Cli::Configuration).to receive(:project_path).and_return('/project')
    expect(Dir).to receive(:exist?).with('/project/pokemonsdk').and_return(false)
    expect(Psdk::Cli::Version).to receive(:puts).with("Project PSDK Version: Studio's PSDK version")

    Psdk::Cli::Version.search_and_show_local_psdk_version
  end

  it 'shows project\'s psdk version' do
    configuration = Psdk::Cli::Configuration.new({})
    expect(Psdk::Cli::Configuration).to receive(:get).with(:local).and_return(configuration)
    allow(Psdk::Cli::Configuration).to receive(:project_path).and_return('/project')
    expect(Dir).to receive(:exist?).with('/project/pokemonsdk').and_return(true)
    expect(Dir).to receive(:exist?).with('.git').and_return(false)
    expect(Dir).to receive(:exist?).with('../.git').and_return(false)
    allow(Dir).to receive(:chdir) { |&block| block.call }.with('/project/pokemonsdk')
    expect(File).to receive(:exist?).with('/project/pokemonsdk/version.txt').and_return(true)
    expect(File).to receive(:read).with('/project/pokemonsdk/version.txt').and_return('4256')
    expect(Psdk::Cli::Version).to receive(:puts).with('Project PSDK version: 16.160')

    Psdk::Cli::Version.search_and_show_local_psdk_version
  end

  it 'shows project\'s psdk version and git version' do
    configuration = Psdk::Cli::Configuration.new({})
    expect(Psdk::Cli::Configuration).to receive(:get).with(:local).and_return(configuration)
    allow(Psdk::Cli::Configuration).to receive(:project_path).and_return('/project')
    expect(Dir).to receive(:exist?).with('/project/pokemonsdk').and_return(true)
    expect(Dir).to receive(:exist?).with('.git').and_return(true)
    expect(Psdk::Cli::Version).to receive(:`).with('git log --oneline -n 1').and_return('ae5fd69 commit message')
    expect(Psdk::Cli::Version).to receive(:`).with('git branch --show-current').and_return('development')
    allow(Dir).to receive(:chdir) { |&block| block.call }.with('/project/pokemonsdk')
    expect(File).to receive(:exist?).with('/project/pokemonsdk/version.txt').and_return(true)
    expect(File).to receive(:read).with('/project/pokemonsdk/version.txt').and_return('4256')
    expect(Psdk::Cli::Version).to receive(:puts).with('Project PSDK version: 16.160')
    expect(Psdk::Cli::Version).to receive(:puts).with("Project's PSDK git target: [development] ae5fd69 commit message")

    Psdk::Cli::Version.search_and_show_local_psdk_version
  end

  it 'shows project\'s psdk version and git version on detached branch' do
    configuration = Psdk::Cli::Configuration.new({})
    expect(Psdk::Cli::Configuration).to receive(:get).with(:local).and_return(configuration)
    allow(Psdk::Cli::Configuration).to receive(:project_path).and_return('/project')
    expect(Dir).to receive(:exist?).with('/project/pokemonsdk').and_return(true)
    expect(Dir).to receive(:exist?).with('.git').and_return(true)
    expect(Psdk::Cli::Version).to receive(:`).with('git log --oneline -n 1').and_return('ae5fd69 commit message')
    expect(Psdk::Cli::Version).to receive(:`).with('git branch --show-current').and_return('')
    allow(Dir).to receive(:chdir) { |&block| block.call }.with('/project/pokemonsdk')
    expect(File).to receive(:exist?).with('/project/pokemonsdk/version.txt').and_return(true)
    expect(File).to receive(:read).with('/project/pokemonsdk/version.txt').and_return('4256')
    expect(Psdk::Cli::Version).to receive(:puts).with('Project PSDK version: 16.160')
    expect(Psdk::Cli::Version).to receive(:puts).with("Project's PSDK git target: [!detached] ae5fd69 commit message")

    Psdk::Cli::Version.search_and_show_local_psdk_version
  end

  it 'shows calls the main show function when no_psdk_version=false' do
    expect(Psdk::Cli::Version).to receive(:puts).with("psdk-cli v#{Psdk::Cli::VERSION}")
    expect(Psdk::Cli::Version).to receive(:print).with('Searching for PSDK version...')
    expect(Psdk::Cli::Version).to receive(:search_and_show_global_psdk_version)
    expect(Psdk::Cli::Version).to receive(:search_and_show_local_psdk_version)

    Psdk::Cli::Version.run(false)
  end
end
# rubocop:enable Metrics/BlockLength
