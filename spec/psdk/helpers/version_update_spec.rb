# frozen_string_literal: true

require 'spec_helper'
require 'psdk/helpers/version_update'

# rubocop:disable Metrics/BlockLength
RSpec.describe Psdk::Cli::VersionUpdate do
  describe '.check_and_update' do
    let(:local_version) { '1.0.0' }
    let(:remote_version) { '1.0.1' }
    let(:gem_search_output) { "psdk-cli (#{remote_version})\n" }

    before do
      stub_const('Psdk::Cli::VERSION', local_version)
      allow(Psdk::Cli::VersionUpdate).to receive(:`).with('gem search -r psdk-cli').and_return(gem_search_output)
      allow(Psdk::Cli::VersionUpdate).to receive(:puts)
      allow(Psdk::Cli::VersionUpdate).to receive(:system)
      allow(Psdk::Cli::VersionUpdate).to receive(:exit)
    end

    context 'when a new version is available' do
      before do
        allow($stdin).to receive(:gets).and_return("y\n")
        allow(Psdk::Cli::VersionUpdate).to receive(:system).and_return(true)
      end

      it 'updates the gem' do
        expect(Psdk::Cli::VersionUpdate).to receive(:print).with('Do you want to update psdk-cli? [Y/n] ')
        expect(Psdk::Cli::VersionUpdate).to receive(:system).with('gem install psdk-cli')
        Psdk::Cli::VersionUpdate.check_and_update
      end

      it 'logs an error and exits if update fails' do
        expect(Psdk::Cli::VersionUpdate).to receive(:print).with('Do you want to update psdk-cli? [Y/n] ')
        expect(Psdk::Cli::VersionUpdate).to receive(:system).with('gem install psdk-cli').and_return(false)
        expect(Psdk::Cli::VersionUpdate).to receive(:exit).with(1)
        expect($stderr).to receive(:puts).with('Failed to update: gem install psdk-cli failed')
        Psdk::Cli::VersionUpdate.check_and_update
      end

      it 'exits after update' do
        expect(Psdk::Cli::VersionUpdate).to receive(:exit)
        Psdk::Cli::VersionUpdate.check_and_update
      end

      context 'when user declines update' do
        before do
          allow($stdin).to receive(:gets).and_return("n\n")
        end

        it 'does not update the gem' do
          expect(Psdk::Cli::VersionUpdate).not_to receive(:system)
          Psdk::Cli::VersionUpdate.check_and_update
        end
      end
    end

    context 'when the local version is up-to-date' do
      let(:remote_version) { '1.0.0' }

      it 'does not update the gem' do
        expect(Psdk::Cli::VersionUpdate).not_to receive(:system)
        Psdk::Cli::VersionUpdate.check_and_update
      end
    end

    context 'when the local version is newer than remote' do
      let(:remote_version) { '0.9.9' }

      it 'does not update the gem' do
        expect(Psdk::Cli::VersionUpdate).not_to receive(:system)
        Psdk::Cli::VersionUpdate.check_and_update
      end
    end

    context 'when gem search fails to find the gem' do
      let(:gem_search_output) { "No match found\n" }

      it 'rescues the error and prints a message' do
        expect($stderr).to receive(:puts).with(
          'Failed to update: Could not find psdk-cli in remote gems'
        )
        Psdk::Cli::VersionUpdate.check_and_update
      end
    end
  end
end
# rubocop:enable Metrics/BlockLength
