# frozen_string_literal: true

require 'spec_helper'
require 'psdk/helpers/psdk'

RSpec.describe Psdk::Cli::PSDK do # rubocop:disable Metrics/BlockLength
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
