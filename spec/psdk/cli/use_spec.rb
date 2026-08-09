# frozen_string_literal: true

# rubocop:disable Metrics/BlockLength
RSpec.describe Psdk::Cli::Use do
  subject { described_class.new }

  describe '#ensure_project' do
    before do
      require 'psdk/cli/configuration'
      allow(Psdk::Cli::Configuration).to receive(:get)
    end

    context 'when project_path is not nil' do
      it 'does not exit' do
        allow(Psdk::Cli::Configuration).to receive(:project_path).and_return('/path/to/project')
        expect { subject.send(:ensure_project) }.not_to raise_error
      end
    end

    context 'when project_path is nil' do
      it 'exits with 1 and prints "Not in a project"' do
        allow(Psdk::Cli::Configuration).to receive(:project_path).and_return(nil)
        expect($stderr).to receive(:puts).with('Not in a project')
        expect(subject).to receive(:exit).with(1)
        subject.send(:ensure_project)
      end
    end
  end

  describe 'public methods' do
    before do
      allow(subject).to receive(:ensure_project)
      allow(Psdk::Cli::PSDK).to receive(:use_version)
      allow(Psdk::Cli::PSDK).to receive(:use_commit)
      allow(Psdk::Cli::PSDK).to receive(:use_mr)
      allow(Psdk::Cli::PSDK).to receive(:use_latest)
    end

    describe '#studio' do
      it 'calls ensure_project' do
        subject.studio
        expect(subject).to have_received(:ensure_project)
      end
    end

    describe '#version' do
      it 'targets the requested official release' do
        expect(Psdk::Cli::PSDK).to receive(:use_version).with('24.15')
        subject.version('24.15')
        expect(subject).to have_received(:ensure_project)
      end
    end

    describe '#commit' do
      it 'targets the requested commit' do
        expect(Psdk::Cli::PSDK).to receive(:use_commit).with('deadcafe')
        subject.commit('deadcafe')
        expect(subject).to have_received(:ensure_project)
      end
    end

    describe '#mr' do
      it 'targets the requested merge request' do
        expect(Psdk::Cli::PSDK).to receive(:use_mr).with('42')
        subject.mr('42')
        expect(subject).to have_received(:ensure_project)
      end
    end

    describe '#latest' do
      it 'targets the latest development commit' do
        expect(Psdk::Cli::PSDK).to receive(:use_latest)
        subject.latest
        expect(subject).to have_received(:ensure_project)
      end
    end
  end
end
# rubocop:enable Metrics/BlockLength
