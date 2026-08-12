# frozen_string_literal: true

require 'spec_helper'
require 'psdk/helpers/psdk'

RSpec.describe Psdk::Cli::PSDK do # rubocop:disable Metrics/BlockLength
  describe 'project version switching' do # rubocop:disable Metrics/BlockLength
    let(:psdk_path) { '/path/to/project/pokemonsdk' }

    before do
      allow(described_class).to receive(:ensure_project_repository).and_return(psdk_path)
      allow(described_class).to receive(:fetch_repository)
      allow(described_class).to receive(:run_git)
      allow(described_class).to receive(:show_active_target)
    end

    it 'checks out the release commit and refreshes submodules' do
      expect(described_class).to receive(:run_git).with(
        psdk_path, 'log', '--format=%H', '--extended-regexp', '--grep=^Release 26\\.58$',
        '--max-count=1', 'origin/release'
      ).and_return('release-sha')
      expect(described_class).to receive(:run_git).with(psdk_path, 'checkout', '--detach', 'release-sha')
      expect(described_class).to receive(:run_git).with(psdk_path, 'submodule', 'update', '--init', '--recursive')
      expect(described_class).to receive(:show_active_target).with(psdk_path, 'official release 26.58')

      described_class.use_version('26.58')
    end

    it 'resolves and checks out a specific commit' do
      expect(described_class).to receive(:run_git).with(
        psdk_path, 'rev-parse', '--verify', '--end-of-options', 'deadcafe^{commit}'
      ).and_return('full-sha')
      expect(described_class).to receive(:run_git).with(psdk_path, 'checkout', '--detach', 'full-sha')
      expect(described_class).to receive(:show_active_target).with(psdk_path, 'commit deadcafe')

      described_class.use_commit('deadcafe')
    end

    it 'fetches an MR by ID and checks out its local branch' do
      expect(described_class).to receive(:run_git).with(
        psdk_path, 'fetch', 'origin',
        '+refs/merge-requests/42/head:refs/remotes/origin/merge-requests/42'
      )
      expect(described_class).to receive(:run_git).with(
        psdk_path, 'checkout', '-B', 'mr-42', 'refs/remotes/origin/merge-requests/42'
      )
      expect(described_class).to receive(:show_active_target).with(psdk_path, 'merge request !42')

      described_class.use_mr('42')
    end

    it 'checks out the latest development commit' do
      expect(described_class).to receive(:run_git).with(
        psdk_path, 'checkout', '-B', 'development', 'origin/development'
      )
      expect(described_class).to receive(:show_active_target).with(psdk_path, 'latest development commit')

      described_class.use_latest
    end

    it 'confirms the active version and commit' do
      allow(described_class).to receive(:show_active_target).and_call_original
      allow(described_class).to receive(:run_git).with(
        psdk_path, 'rev-parse', '--short', 'HEAD'
      ).and_return('deadcafe')
      allow(File).to receive(:read).with(File.join(psdk_path, 'version.txt')).and_return('6714')
      expect(described_class).to receive(:puts).with(
        'Active PSDK: official release 26.58 (version 26.58, commit deadcafe)'
      )

      described_class.send(:show_active_target, psdk_path, 'official release 26.58')
    end
  end

  describe '.ensure_project_repository' do
    let(:project_path) { '/path/to/project' }
    let(:psdk_path) { File.join(project_path, 'pokemonsdk') }
    let(:old_psdk_path) { "#{psdk_path}_old" }

    before do
      allow(Psdk::Cli::Configuration).to receive(:project_path).and_return(project_path)
    end

    context 'when the pokemonsdk folder is already a git repository' do
      it 'returns the path without cloning or restoring' do
        allow(File).to receive(:exist?).with(File.join(psdk_path, '.git')).and_return(true)
        expect(described_class).not_to receive(:restore_old_pokemonsdk_folder)
        expect(described_class).not_to receive(:system)

        expect(described_class.send(:ensure_project_repository)).to eq(psdk_path)
      end
    end

    context 'when the pokemonsdk folder exists but is not a git repository' do
      it 'raises an error' do
        allow(File).to receive(:exist?).with(File.join(psdk_path, '.git')).and_return(false)
        allow(Dir).to receive(:exist?).with(psdk_path).and_return(true)

        expect { described_class.send(:ensure_project_repository) }.to raise_error("#{psdk_path} exists but is not a Git repository")
      end
    end

    context 'when a matching pokemonsdk_old folder exists' do
      it 'restores it instead of cloning' do
        allow(File).to receive(:exist?).with(File.join(psdk_path, '.git')).and_return(false)
        allow(Dir).to receive(:exist?).with(psdk_path).and_return(false)
        expect(described_class).to receive(:restore_old_pokemonsdk_folder).with(psdk_path).and_return(true)
        expect(described_class).not_to receive(:system)

        expect(described_class.send(:ensure_project_repository)).to eq(psdk_path)
      end
    end

    context 'when there is no usable pokemonsdk_old folder' do
      it 'clones the main repository' do
        allow(File).to receive(:exist?).with(File.join(psdk_path, '.git')).and_return(false)
        allow(Dir).to receive(:exist?).with(psdk_path).and_return(false)
        expect(described_class).to receive(:restore_old_pokemonsdk_folder).with(psdk_path).and_return(false)
        expect(described_class).to receive(:system).with('git', 'clone', described_class::MAIN_REPOSITORY_URL, psdk_path).and_return(true)

        expect(described_class.send(:ensure_project_repository)).to eq(psdk_path)
      end

      it 'raises an error when cloning fails' do
        allow(File).to receive(:exist?).with(File.join(psdk_path, '.git')).and_return(false)
        allow(Dir).to receive(:exist?).with(psdk_path).and_return(false)
        allow(described_class).to receive(:restore_old_pokemonsdk_folder).with(psdk_path).and_return(false)
        allow(described_class).to receive(:system).with('git', 'clone', described_class::MAIN_REPOSITORY_URL, psdk_path).and_return(false)

        expect { described_class.send(:ensure_project_repository) }.to raise_error("Failed to clone pokemonsdk into `#{psdk_path}`")
      end
    end
  end

  describe '.restore_old_pokemonsdk_folder' do
    let(:psdk_path) { '/path/to/project/pokemonsdk' }
    let(:old_psdk_path) { "#{psdk_path}_old" }

    context 'when pokemonsdk_old does not exist' do
      it 'returns false without renaming' do
        allow(File).to receive(:exist?).with(File.join(old_psdk_path, '.git')).and_return(false)
        expect(File).not_to receive(:rename)

        expect(described_class.send(:restore_old_pokemonsdk_folder, psdk_path)).to be(false)
      end
    end

    context 'when pokemonsdk_old exists but points to another repository' do
      it 'returns false without renaming' do
        allow(File).to receive(:exist?).with(File.join(old_psdk_path, '.git')).and_return(true)
        allow(described_class).to receive(:remote_matches_main_repository?).with(old_psdk_path).and_return(false)
        expect(File).not_to receive(:rename)

        expect(described_class.send(:restore_old_pokemonsdk_folder, psdk_path)).to be(false)
      end
    end

    context 'when pokemonsdk_old exists and points to the main repository' do
      it 'renames it to pokemonsdk and returns true' do
        allow(File).to receive(:exist?).with(File.join(old_psdk_path, '.git')).and_return(true)
        allow(described_class).to receive(:remote_matches_main_repository?).with(old_psdk_path).and_return(true)
        expect(File).to receive(:rename).with(old_psdk_path, psdk_path)

        expect(described_class.send(:restore_old_pokemonsdk_folder, psdk_path)).to be(true)
      end
    end
  end

  describe '.remote_matches_main_repository?' do
    let(:psdk_path) { '/path/to/project/pokemonsdk_old' }

    it 'returns true when the origin remote matches the main repository' do
      allow(described_class).to receive(:run_git).with(psdk_path, 'remote', 'get-url', 'origin')
                                                   .and_return(described_class::MAIN_REPOSITORY_URL)

      expect(described_class.send(:remote_matches_main_repository?, psdk_path)).to be(true)
    end

    it 'returns false when the origin remote points elsewhere' do
      allow(described_class).to receive(:run_git).with(psdk_path, 'remote', 'get-url', 'origin')
                                                   .and_return('https://gitlab.com/someone-else/pokemonsdk.git')

      expect(described_class.send(:remote_matches_main_repository?, psdk_path)).to be(false)
    end

    it 'returns false when git raises an error' do
      allow(described_class).to receive(:run_git).with(psdk_path, 'remote', 'get-url', 'origin')
                                                   .and_raise('git remote get-url origin failed')

      expect(described_class.send(:remote_matches_main_repository?, psdk_path)).to be(false)
    end
  end

  describe '.unuse_local_pokemonsdk' do # rubocop:disable Metrics/BlockLength
    let(:project_path) { '/path/to/project' }
    let(:psdk_path) { File.join(project_path, 'pokemonsdk') }
    let(:delete_option) { false }

    before do
      allow(Psdk::Cli::Configuration).to receive(:project_path).and_return(project_path)
      allow(File).to receive(:join).with(project_path, 'pokemonsdk').and_return(psdk_path)
      # Allow File.join with other arguments to work as usual
      allow(File).to receive(:join).and_call_original
      allow(Psdk::Cli::PSDK).to receive(:puts)
      allow(Psdk::Cli::PSDK).to receive(:exit) { raise 'Exited 1' }
      allow(FileUtils).to receive(:rm_rf)
      allow(File).to receive(:rename)
      allow(Psdk::Cli::PSDK).to receive(:system)
    end

    context 'when psdk folder does not exist' do
      before do
        allow(Dir).to receive(:exist?).with(psdk_path).and_return(false)
      end

      it 'does nothing' do
        expect(Psdk::Cli::PSDK).not_to receive(:git_project?)
        expect(FileUtils).not_to receive(:rm_rf)
        expect(File).not_to receive(:rename)

        Psdk::Cli::PSDK.unuse_local_pokemonsdk(delete: delete_option)
      end
    end

    context 'when psdk folder exists' do # rubocop:disable Metrics/BlockLength
      before do
        allow(Dir).to receive(:exist?).with(psdk_path).and_return(true)
        # Default non-git, non-submodule for basic checking unless overridden
        allow(Psdk::Cli::PSDK).to receive(:git_project?).with(project_path).and_return(false)
        allow(Psdk::Cli::PSDK).to receive(:submodule?).with(project_path).and_return(false)
      end

      context 'when it is not a git submodule' do # rubocop:disable Metrics/BlockLength
        context 'with delete: true' do
          let(:delete_option) { true }

          it 'deletes the folder' do
            expect(FileUtils).to receive(:rm_rf).with(psdk_path)
            expect(Psdk::Cli::PSDK).to receive(:puts).with(
              "Successfully set project to use Pokémon Studio's PSDK version"
            )

            Psdk::Cli::PSDK.unuse_local_pokemonsdk(delete: delete_option)
          end
        end

        context 'with delete: false' do
          let(:delete_option) { false }
          let(:new_path) { "#{psdk_path}_old" }

          context 'when _old folder already exists' do
            before do
              allow(File).to receive(:exist?).with(new_path).and_return(true)
            end

            it 'exits with error' do
              expect(Psdk::Cli::PSDK).to receive(:puts).with(
                "[Error] Folder `#{new_path}` already exists. Please remove it manually."
              )
              expect { Psdk::Cli::PSDK.unuse_local_pokemonsdk(delete: delete_option) }.to raise_error('Exited 1')
            end
          end

          context 'when _old folder does not exist' do
            before do
              allow(File).to receive(:exist?).with(new_path).and_return(false)
            end

            it 'renames the folder' do
              expect(File).to receive(:rename).with(psdk_path, new_path)
              expect(Psdk::Cli::PSDK).to receive(:puts).with(
                "Successfully set project to use Pokémon Studio's PSDK version"
              )

              Psdk::Cli::PSDK.unuse_local_pokemonsdk(delete: delete_option)
            end
          end
        end
      end

      context 'when it IS a git submodule' do # rubocop:disable Metrics/BlockLength
        before do
          allow(Psdk::Cli::PSDK).to receive(:git_project?).with(project_path).and_return(true)
          allow(Psdk::Cli::PSDK).to receive(:submodule?).with(project_path).and_return(true)
        end

        context 'with delete: false' do
          let(:delete_option) { false }

          it 'exits with error advising to remove submodule manually' do
            expect(Psdk::Cli::PSDK).to receive(:puts).with(
              "[Error] Cannot use Studio's PSDK version if the project has a submodule."
            )
            expect(Psdk::Cli::PSDK).to receive(:puts).with('Please follow this guide to remove the submodule: https://stackoverflow.com/a/1260982')
            expect { Psdk::Cli::PSDK.unuse_local_pokemonsdk(delete: delete_option) }.to raise_error('Exited 1')
          end
        end

        context 'with delete: true' do # rubocop:disable Metrics/BlockLength
          let(:delete_option) { true }

          it 'removes the submodule successfully' do
            # Mock successful git commands
            expect(Psdk::Cli::PSDK).to receive(:system).with('git', 'submodule', 'deinit', '-f', 'pokemonsdk',
                                                             chdir: project_path, out: File::NULL, err: File::NULL).and_return(true)
            expect(Psdk::Cli::PSDK).to receive(:system).with('git', 'rm', '-f', 'pokemonsdk', chdir: project_path,
                                                                                              out: File::NULL, err: File::NULL).and_return(true)

            # Module folder cleanup
            expect(FileUtils).to receive(:rm_rf).with(File.join(project_path, '.git', 'modules', 'pokemonsdk'))

            expect(Psdk::Cli::PSDK).to receive(:puts).with('Successfully removed the submodule')
            expect(Psdk::Cli::PSDK).to receive(:puts).with(
              "Successfully set project to use Pokémon Studio's PSDK version"
            )

            Psdk::Cli::PSDK.unuse_local_pokemonsdk(delete: delete_option)
          end

          it 'fails to deinit submodule' do
            expect(Psdk::Cli::PSDK).to receive(:system).with('git', 'submodule', 'deinit', any_args).and_return(false)

            expect(Psdk::Cli::PSDK).to receive(:puts).with(
              '[Error] Failed to remove the submodule (Failed to deinit pokemonsdk submodule)'
            )
            expect { Psdk::Cli::PSDK.unuse_local_pokemonsdk(delete: delete_option) }.to raise_error('Exited 1')
          end

          it 'fails to remove submodule' do
            expect(Psdk::Cli::PSDK).to receive(:system).with('git', 'submodule', 'deinit', any_args).and_return(true)
            expect(Psdk::Cli::PSDK).to receive(:system).with('git', 'rm', any_args).and_return(false)

            expect(Psdk::Cli::PSDK).to receive(:puts).with(
              '[Error] Failed to remove the submodule (Failed to remove pokemonsdk submodule)'
            )
            expect { Psdk::Cli::PSDK.unuse_local_pokemonsdk(delete: delete_option) }.to raise_error('Exited 1')
          end
        end
      end
    end
  end
end
