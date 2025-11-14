# frozen_string_literal: true

# rubocop:disable Metrics/BlockLength
RSpec.describe Psdk::Cli::Studio do
  it 'provides Studio location in AppData' do
    expect(ENV).to receive(:fetch).with('AppData', '.').and_return('C:/Users/User/AppData/Roaming')

    expect(Psdk::Cli::Studio.studio_app_data_location).to eq(
      'C:/Users/User/AppData/Roaming/../Local/Programs/pokemon-studio'
    )
  end

  it 'provides all common locations' do
    expect(ENV).to receive(:fetch).with('AppData', '.').and_return('C:/Users/User/AppData/Roaming')
    allow(ENV).to receive(:[]).with('AppData').and_return('C:/Users/User/AppData/Roaming')
    allow(Dir).to receive(:[]) { |path| path.include?('Volumes') ? ['/Volumes/HDD'] : ['/dev/sda1'] }

    options = ['/Applications/PokemonStudio.app', 'C:/Users/User/AppData/Roaming/../Local/Programs/pokemon-studio',
               '/Volumes/HDD/projects/PokemonStudio', '/dev/sda1/projects/PokemonStudio',
               'C:/Projects/PokemonStudio']
    expect(Psdk::Cli::Studio.common_studio_location).to eq(options)
  end

  it 'provides few common locations' do
    allow(ENV).to receive(:[]).with('AppData').and_return(nil)
    allow(Dir).to receive(:[]) { [] }

    options = ['/Applications/PokemonStudio.app', 'C:/Projects/PokemonStudio']
    expect(Psdk::Cli::Studio.common_studio_location).to eq(options)
  end

  it 'checks if psdk-binaries exists in provided location' do
    allow(Dir).to receive(:exist?) { |path| path == '/path/resources/psdk-binaries' }

    expect { Psdk::Cli::Studio.check_psdk_binaries_in_provided_location('/path') }.not_to raise_error
  end

  it 'raises ArgumentError if the psdk-binaries does not exists in provided location' do
    allow(Dir).to receive(:exist?) { false }
    expect(Psdk::Cli::Studio).to receive(:puts).with('Provided path does not contain psdk-binaries')

    expect { Psdk::Cli::Studio.check_psdk_binaries_in_provided_location('/path') }.to raise_error(ArgumentError)
  end

  it 'asks for Studio path' do
    configuration = Psdk::Cli::Configuration.new({})
    allow(Dir).to receive(:exist?) { |path| path == '/path/resources/psdk-binaries' }
    allow($stdin).to receive(:gets).and_return("/path\n")
    expect(Psdk::Cli::Studio).to receive(:print).with(
      "\rCould not automatically find Pokémon Studio path, please enter it:"
    )
    expect(Psdk::Cli::Configuration).to receive(:get).with(:global).and_return(configuration)
    expect(configuration).to receive(:studio_path=).with('/path')
    expect(Psdk::Cli::Configuration).to receive(:save)

    Psdk::Cli::Studio.ask_and_save_studio_path
  end

  it 'asks for Studio path until a valid one is provided' do
    configuration = Psdk::Cli::Configuration.new({})
    i = 0
    allow(Dir).to receive(:exist?) { |path| path == '/valid_path/resources/psdk-binaries' }
    allow($stdin).to receive(:gets) { (i += 1) == 1 ? "/path\n" : "/valid_path\n" }
    expect(Psdk::Cli::Studio).to receive(:puts).with('Provided path does not contain psdk-binaries').exactly(1).times
    expect(Psdk::Cli::Studio).to(
      receive(:print).with("\rCould not automatically find Pokémon Studio path, please enter it:").exactly(2).times
    )
    expect(Psdk::Cli::Configuration).to receive(:get).with(:global).and_return(configuration).exactly(1).times
    expect(configuration).to receive(:studio_path=).with('/valid_path')
    expect(Psdk::Cli::Configuration).to receive(:save)

    Psdk::Cli::Studio.ask_and_save_studio_path
  end

  it 'returns the psdk-binaries path based on studio path' do
    allow(Dir).to receive(:exist?) { |path| path == '/path/resources/psdk-binaries' }

    expect(Psdk::Cli::Studio.psdk_binaries_path('/path')).to eq('/path/resources/psdk-binaries')
  end

  it 'returns nil as psdk-binaries path if none match' do
    allow(Dir).to receive(:exist?) { false }

    expect(Psdk::Cli::Studio.psdk_binaries_path('/path')).to eq(nil)
  end

  it 'finds the Studio path' do
    configuration = Psdk::Cli::Configuration.new({})
    valid_paths = ['/Applications/PokemonStudio.app',
                   '/Applications/PokemonStudio.app/Contents/Resources/psdk-binaries']
    allow(Dir).to receive(:exist?) { |path| valid_paths.include?(path) }
    expect(Psdk::Cli::Studio).to receive(:puts).with("\rLocated Pokemon Studio in `/Applications/PokemonStudio.app`")
    expect(Psdk::Cli::Configuration).to receive(:get).with(:global).and_return(configuration)
    expect(configuration).to receive(:studio_path=).with('/Applications/PokemonStudio.app')
    expect(Psdk::Cli::Configuration).to receive(:save)

    Psdk::Cli::Studio.find_and_save_path
  end

  it 'ask Studio path if target folder does not contains psdk-binaries' do
    valid_paths = ['/Applications/PokemonStudio.app']
    allow(Dir).to receive(:exist?) { |path| valid_paths.include?(path) }
    expect(Psdk::Cli::Studio).not_to receive(:puts)
    expect(Psdk::Cli::Configuration).not_to receive(:get).with(:global)
    expect(Psdk::Cli::Configuration).not_to receive(:save)
    expect(Psdk::Cli::Studio).to receive(:ask_and_save_studio_path)

    Psdk::Cli::Studio.find_and_save_path
  end

  it 'ask Studio path if no common path is found' do
    allow(Dir).to receive(:exist?) { false }
    expect(Psdk::Cli::Studio).not_to receive(:puts)
    expect(Psdk::Cli::Configuration).not_to receive(:get).with(:global)
    expect(Psdk::Cli::Configuration).not_to receive(:save)
    expect(Psdk::Cli::Studio).to receive(:ask_and_save_studio_path)

    Psdk::Cli::Studio.find_and_save_path
  end
end
# rubocop:enable Metrics/BlockLength
