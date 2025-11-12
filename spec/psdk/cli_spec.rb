# frozen_string_literal: true

RSpec.describe Psdk::Cli do
  it 'has a version number' do
    expect(Psdk::Cli::VERSION).not_to be nil
  end
end
