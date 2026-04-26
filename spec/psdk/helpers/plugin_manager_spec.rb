# frozen_string_literal: true

require 'psdk/helpers/plugin_manager'

RSpec.describe Psdk::Helpers::PluginManager do
  describe '.list' do
    it 'calls List.list_plugins' do
      expect(Psdk::Helpers::PluginManager::List).to receive(:list_plugins)
      described_class.list
    end
  end

  describe '.build' do
    it 'instantiates Builder and calls build' do
      builder_mock = instance_double(Psdk::Helpers::PluginManager::Builder)
      expect(Psdk::Helpers::PluginManager::Builder).to(
        receive(:new).with('my_plugin', in_project: '/path/to/project', out_dir: '.').and_return(builder_mock)
      )
      expect(builder_mock).to receive(:build)

      described_class.build('my_plugin', in_project: '/path/to/project', out_dir: '.')
    end
  end
end

RSpec.describe Psdk::Helpers::PluginManager::List do
  describe '.list_plugins' do
    before do
      allow(File).to receive(:exist?).and_return(true)
      allow(File).to receive(:binread).and_return('mocked_data')

      plugin_mock = Psdk::Helpers::PluginManager::Config.new
      plugin_mock.name = 'TestPlugin'
      plugin_mock.version = '1.0'
      plugin_mock.authors = ['Test Author']

      allow(Marshal).to receive(:load).and_return([plugin_mock])
      allow($stdout).to receive(:puts)
    end

    it 'prints the plugins' do
      expect($stdout).to receive(:puts).with(/- \e\[34mTestPlugin\e\[36m v1.0\e\[0m/)
      described_class.list_plugins
    end
  end
end

RSpec.describe Psdk::Helpers::PluginManager::Builder do # rubocop:disable Metrics/BlockLength
  let(:plugin_name) { 'my_plugin' }
  subject { described_class.new(plugin_name, in_project: in_project, out_dir: '.') }

  describe '#build' do # rubocop:disable Metrics/BlockLength
    let(:yuki_vd_mock) { instance_double(Yuki::VD) }
    let(:config_hash) { { 'name' => 'test_plugin', 'version' => '1.0' } }

    before do
      allow($stdout).to receive(:puts)
      allow(Yuki::VD).to receive(:new).and_return(yuki_vd_mock)
      allow(yuki_vd_mock).to receive(:write_data)
      allow(yuki_vd_mock).to receive(:close)

      allow(File).to(
        receive(:read).with(/config\.yml/).and_return("name: test_plugin\nversion: 1.0\nadded_files:\n  - '*'\n")
      )
      config_hash_with_files = config_hash.merge('added_files' => ['*.png'])
      allow(YAML).to receive(:unsafe_load).and_return(config_hash_with_files)
      allow(File).to receive(:exist?).and_return(true)
      allow(File).to receive(:binread).and_return("\x00" * 32)
      allow(File).to receive(:rename)
      allow(Dir).to receive(:chdir).and_yield
    end

    context 'when in a PSDK project' do
      let(:in_project) { '/path/to/project' }

      it 'uses project script paths' do
        expect(subject).to receive(:add_scripts).and_call_original
        expect(Dir).to receive(:[]).with('scripts/my_plugin/scripts/**/*.rb').and_return([])
        expect(Dir).to receive(:[]).with('*.png').and_return([]) # added_files is empty

        subject.build
      end
    end

    context 'when in standalone mode' do
      let(:in_project) { false }
      let(:plugin_name) { '.' }

      it 'uses standalone script paths' do
        expect(subject).to receive(:add_scripts).and_call_original
        expect(Dir).to receive(:[]).with('./scripts/**/*.rb').and_return([])
        expect(Dir).to receive(:[]).with('*.png').and_return([]) # added_files is empty

        subject.build
      end
    end
  end
end
