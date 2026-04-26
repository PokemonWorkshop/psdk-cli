# frozen_string_literal: true

require 'psdk/cli/plugin'
require 'psdk/cli/configuration'

RSpec.describe Psdk::Cli::Plugin do # rubocop:disable Metrics/BlockLength
  subject { described_class.new }

  describe '#list' do
    context 'when in a PSDK project' do
      let(:config_mock) { double('Configuration', project_path: '/path/to/project') }

      before do
        allow(Psdk::Cli::Configuration).to receive(:get).with(:local).and_return(config_mock)
        allow(Psdk::Helpers::PluginManager).to receive(:list)
      end

      it 'calls Psdk::Helpers::PluginManager.list' do
        expect(Psdk::Helpers::PluginManager).to receive(:list)
        subject.list
      end
    end

    context 'when not in a PSDK project' do
      before do
        allow(Psdk::Cli::Configuration).to receive(:get).with(:local)
        allow(Psdk::Cli::Configuration).to receive(:project_path).and_return(nil)
      end

      it 'exits with 1 and prints an error' do
        expect($stdout).to receive(:puts).with(/You must be inside a PSDK project/)
        expect { subject.list }.to raise_error(SystemExit) { |e| expect(e.status).to eq(1) }
      end
    end
  end

  describe '#build' do # rubocop:disable Metrics/BlockLength
    before do
      allow(Psdk::Cli::Configuration).to receive(:get).with(:local)
      allow(Psdk::Cli::Configuration).to receive(:project_path).and_return('/path/to/project')
      allow(Psdk::Helpers::PluginManager).to receive(:build)
      subject.options = { out_dir: '.' }
    end

    context 'when in a PSDK project' do
      it 'calls Psdk::Helpers::PluginManager.build with plugin name' do
        expect(Psdk::Helpers::PluginManager).to(
          receive(:build).with('my_plugin', in_project: '/path/to/project', out_dir: '.')
        )
        subject.build('my_plugin')
      end

      it 'exits with 1 if no plugin_name is provided' do
        expect($stdout).to receive(:puts).with(/You must provide a plugin_name/)
        expect { subject.build(nil) }.to raise_error(SystemExit) { |e| expect(e.status).to eq(1) }
      end
    end

    context 'when in standalone mode' do
      let(:config_mock) { double('Configuration', project_path: nil) }

      it 'calls Psdk::Helpers::PluginManager.build with default name' do
        expect(Psdk::Helpers::PluginManager).to receive(:build).with('.', in_project: nil, out_dir: '.')
        subject.build(nil)
      end

      it 'calls Psdk::Helpers::PluginManager.build with provided name' do
        expect(Psdk::Helpers::PluginManager).to receive(:build).with('my_plugin', in_project: nil, out_dir: '.')
        subject.build('my_plugin')
      end
    end

    context 'when forcing standalone mode with flag' do
      before do
        subject.options = { no_psdk_project: true, out_dir: '.' }
      end

      it 'builds with in_project: false despite being in a project' do
        expect(Psdk::Helpers::PluginManager).to receive(:build).with('my_plugin', in_project: false, out_dir: '.')
        subject.build('my_plugin')
      end
    end
  end
end
