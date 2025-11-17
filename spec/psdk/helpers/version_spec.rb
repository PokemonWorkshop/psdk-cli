# frozen_string_literal: true

# rubocop:disable Metrics/BlockLength
RSpec.describe Psdk::Cli::Version do
  it 'only prints the cli version' do
    expect(Psdk::Cli::Version).to receive(:puts).with("psdk-cli v#{Psdk::Cli::VERSION}")
    expect(Psdk::Cli::Version).not_to receive(:print).with("Searching for PSDK version...\r")
    expect(Psdk::Cli::Version).not_to receive(:search_and_show_global_psdk_version)
    expect(Psdk::Cli::Version).not_to receive(:search_and_show_local_psdk_version)

    Psdk::Cli::Version.run(true)
  end

  it 'search and show global psdk version based on cloned repository' do
    expect(Psdk::Cli::PSDK).to receive(:ensure_repository_cloned)
    expect(Psdk::Cli::PSDK).to receive(:repository_path).and_return('/psdk_repository_path')
    expect(Psdk::Cli::Version).to receive(:show_global_psdk_version).with('/psdk_repository_path')
    expect(Psdk::Cli::Version).to receive(:load_git_data).with('/psdk_repository_path').and_return(
      '[development] aaaaaa commit'
    )
    expect(Psdk::Cli::Version).to receive(:puts).with('Global PSDK git Target: [development] aaaaaa commit')

    Psdk::Cli::Version.search_and_show_global_psdk_version
  end

  it 'shows global version' do
    expect(File).to receive(:exist?).with('/psdk_repository_path/version.txt').and_return(true)
    expect(File).to receive(:read).with('/psdk_repository_path/version.txt').and_return('4256')
    expect(Psdk::Cli::Version).to receive(:puts).with('Global PSDK version: 16.160       ')

    Psdk::Cli::Version.show_global_psdk_version('/psdk_repository_path')
  end

  it 'shows global version even if version.txt was not found (unlikely)' do
    expect(File).to receive(:exist?).with('/psdk_repository_path/version.txt').and_return(false)
    expect(Psdk::Cli::Version).to receive(:puts).with('Global PSDK version: 0       ')

    Psdk::Cli::Version.show_global_psdk_version('/psdk_repository_path')
  end

  it 'do not show local version if no project is configured' do
    configuration = Psdk::Cli::Configuration.new({})
    expect(Psdk::Cli::Configuration).to receive(:get).with(:local).and_return(configuration)
    expect(Psdk::Cli::Configuration).to receive(:project_path).and_return(nil)

    Psdk::Cli::Version.search_and_show_local_psdk_version
  end

  it 'shows "studio\'s version" if no local pokemonsdk folder exists' do
    allow(Dir).to receive(:exist?).with('/studio_path').and_return(true)

    configuration = Psdk::Cli::Configuration.new({ studio_path: '/studio_path' })
    allow(Psdk::Cli::Configuration).to receive(:get).with(:local).and_return(configuration)
    allow(Psdk::Cli::Configuration).to receive(:project_path).and_return('/project')

    expect(Dir).to receive(:exist?).with('/project/pokemonsdk').and_return(false)
    expect(Psdk::Cli::Studio).to receive(:psdk_binaries_path).with('/studio_path').and_return(
      '/studio_path/psdk-binaries'
    )
    expect(File).to receive(:exist?).with('/studio_path/psdk-binaries/pokemonsdk/version.txt').and_return(true)
    expect(File).to receive(:read).with('/studio_path/psdk-binaries/pokemonsdk/version.txt').and_return('4256')

    expect(Psdk::Cli::Version).to receive(:puts).with('Project PSDK Version: 16.160 (Pokémon Studio)')
    Psdk::Cli::Version.search_and_show_local_psdk_version
  end

  it 'shows error for local project if Studio and repository are not found' do
    allow(Dir).to receive(:exist?).with('/studio_path').and_return(true)

    configuration = Psdk::Cli::Configuration.new({ studio_path: '/studio_path' })
    allow(Psdk::Cli::Configuration).to receive(:get).with(:local).and_return(configuration)
    allow(Psdk::Cli::Configuration).to receive(:project_path).and_return('/project')

    expect(Dir).to receive(:exist?).with('/project/pokemonsdk').and_return(false)
    expect(Psdk::Cli::Studio).to receive(:psdk_binaries_path).with('/studio_path').and_return(nil)

    expect(Psdk::Cli::Version).to receive(:puts).with(
      'Project PSDK Version: Cannot locate Pokémon Studio or local repository...'
    )
    expect(Psdk::Cli::Version).to receive(:exit).with(1) { raise 'exit 1' }
    expect { Psdk::Cli::Version.search_and_show_local_psdk_version }.to raise_error(RuntimeError, 'exit 1')
  end

  it 'calls Studio.find_and_save_path if studio path is empty when searching local psdk version' do
    configuration = Psdk::Cli::Configuration.new({})
    allow(Dir).to receive(:exist?).with('/studio_path').and_return(true)
    expect(Psdk::Cli::Studio).to receive(:find_and_save_path) { configuration.studio_path = '/studio_path' }
    allow(Psdk::Cli::Configuration).to receive(:get).with(:local).and_return(configuration)
    allow(Psdk::Cli::Configuration).to receive(:project_path).and_return('/project')

    expect(Dir).to receive(:exist?).with('/project/pokemonsdk').and_return(false)
    expect(Psdk::Cli::Studio).to receive(:psdk_binaries_path).with('/studio_path').and_return(
      '/studio_path/psdk-binaries'
    )
    expect(File).to receive(:exist?).with('/studio_path/psdk-binaries/pokemonsdk/version.txt').and_return(true)
    expect(File).to receive(:read).with('/studio_path/psdk-binaries/pokemonsdk/version.txt').and_return('4256')

    expect(Psdk::Cli::Version).to receive(:puts).with('Project PSDK Version: 16.160 (Pokémon Studio)')
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
    expect(Psdk::Cli::Version).to receive(:print).with("Searching for PSDK version...\r")
    expect(Psdk::Cli::Version).to receive(:search_and_show_global_psdk_version)
    expect(Psdk::Cli::Version).to receive(:search_and_show_local_psdk_version)

    Psdk::Cli::Version.run(false)
  end
end
# rubocop:enable Metrics/BlockLength
