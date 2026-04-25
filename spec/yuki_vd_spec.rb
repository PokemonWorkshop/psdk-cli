# frozen_string_literal: true

require_relative '../lib/psdk/helpers/900 Yuki__VD'

RSpec.describe Yuki::VD do # rubocop:disable Metrics/BlockLength
  let(:vd_filename) { 'test.vd' }
  let(:file_double) { instance_double(File) }
  let(:string_io_double) { instance_double(StringIO) }
  let(:pointer_size) { 4 }
  # MAX_SIZE is 10MB
  let(:max_size) { 10 * 1024 * 1024 }

  before do
    # Mock File class methods
    allow(File).to receive(:new).and_return(file_double)
    allow(File).to receive(:binread)
    allow(File).to receive(:exist?).and_return(false)
    allow(File).to receive(:delete)
    allow(StringIO).to receive(:new).and_return(string_io_double)

    # Mock File instance methods
    allow(file_double).to receive(:pos=)
    allow(file_double).to receive(:pos).and_return(0)
    allow(file_double).to receive(:read)
    allow(file_double).to receive(:write)
    allow(file_double).to receive(:close)
    allow(string_io_double).to receive(:pos=)
    allow(string_io_double).to receive(:pos).and_return(0)
    allow(string_io_double).to receive(:read)
    allow(string_io_double).to receive(:write)
    allow(string_io_double).to receive(:close)

    # Mock Marshal since it interacts with the file
    allow(Marshal).to receive(:dump).and_return('marshaled_data')
    allow(Marshal).to receive(:load).and_return({})
  end

  context 'when writing a new VD' do # rubocop:disable Metrics/BlockLength
    it 'creates a file with write mode' do
      Yuki::VD.new(vd_filename, :write)
      expect(File).to have_received(:new).with(vd_filename, 'wb')
    end

    it 'writes data correctly' do
      vd = Yuki::VD.new(vd_filename, :write)
      filename = 'test.txt'
      data = 'content'

      # Mock pos to return a specific offset for the file
      allow(file_double).to receive(:pos).and_return(123)

      vd.write_data(filename, data)

      expect(file_double).to have_received(:write).with([data.bytesize].pack('L'))
      expect(file_double).to have_received(:write).with(data)
    end

    it 'writes header and hash on close' do
      vd = Yuki::VD.new(vd_filename, :write)
      filename = 'test.txt'
      data = 'content'

      # Position of the file when attempting to write data
      allow(file_double).to receive(:pos).and_return(250)
      vd.write_data(filename, data)

      # Position of the file when closing
      allow(file_double).to receive(:pos).and_return(500)
      vd.close

      expect(Marshal).to have_received(:dump).with({ filename => 250 })
      expect(file_double).to have_received(:write).with('marshaled_data')
      expect(file_double).to have_received(:pos=).with(0)
      expect(file_double).to have_received(:write).with([500].pack('L'))
      expect(file_double).to have_received(:close)
    end

    it 'adds a file using File.binread' do
      vd = Yuki::VD.new(vd_filename, :write)
      allow(File).to receive(:binread).with('external.txt').and_return('external content')

      vd.add_file('external.txt')

      expect(File).to have_received(:binread).with('external.txt')
      expect(file_double).to have_received(:write).with('external content')
    end
  end

  context 'when reading an existing VD' do # rubocop:disable Metrics/BlockLength
    let(:fake_pointer) { 100 }

    before do
      # Setup for read mode: read pointer, then Marshal.load
      allow(file_double).to receive(:read).with(pointer_size).and_return([fake_pointer].pack('L'))
      allow(Marshal).to receive(:load).and_return({ 'test.txt' => 50 })
    end

    it 'opens the file in read mode' do
      # We need to ensure load_whole_file is NOT called for this test to keep using file_double
      # If fake_pointer < MAX_SIZE, it loads whole file.
      # Let's set fake_pointer to MAX_SIZE + 1 to avoid loading into memory for this test
      allow(file_double).to receive(:read).with(pointer_size).and_return([max_size + 1].pack('L'))

      Yuki::VD.new(vd_filename, :read)
      expect(File).to have_received(:new).with(vd_filename, 'rb')
    end

    it 'reads data from the file' do
      content = 'file content'
      size = content.bytesize

      # Avoid load_whole_file
      allow(file_double).to receive(:read).with(pointer_size).and_return(
        [max_size + 1].pack('L'), # First call in initialize
        [size].pack('L')          # Second call in read_data (size)
      )

      # Ensure read(size) returns content
      allow(file_double).to receive(:read).with(size).and_return(content)

      vd = Yuki::VD.new(vd_filename, :read)
      result = vd.read_data('test.txt')

      expect(file_double).to have_received(:pos=).with(50)
      expect(result).to eq(content)
    end

    it 'loads into memory (StringIO) if file is small' do
      # fake_pointer is 100, which is < MAX_SIZE
      # It will call load_whole_file(100)
      allow(file_double).to receive(:read).with(pointer_size).and_return([100].pack('L'))
      allow(file_double).to receive(:read).with(100).and_return('whole file content')

      vd = Yuki::VD.new(vd_filename, :read)

      # Verify it read the whole file and closed the original file handle
      expect(file_double).to have_received(:read).with(100)
      expect(file_double).to have_received(:close)

      # Verify @file is now a StringIO
      expect(vd.instance_variable_get(:@file)).to eq(string_io_double)
    end
  end

  context 'when updating a VD' do
    let(:fake_pointer) { 200 }

    before do
      allow(file_double).to receive(:read).with(pointer_size).and_return([fake_pointer].pack('L'))
      allow(Marshal).to receive(:load).and_return({})
    end

    it 'opens the file in update mode' do
      Yuki::VD.new(vd_filename, :update)
      expect(File).to have_received(:new).with(vd_filename, 'rb+')
    end

    it 'restores position after loading hash' do
      Yuki::VD.new(vd_filename, :update)
      # pos= is called twice: once to store return value of read, once to restore position
      expect(file_double).to have_received(:pos=).with(fake_pointer).at_least(:once)
    end

    it 'writes new data and updates hash on close' do
      vd = Yuki::VD.new(vd_filename, :update)

      # Simulate adding a file
      allow(file_double).to receive(:pos).and_return(300)
      vd.write_data('new.txt', 'data')

      vd.close

      # Should write updated hash and new pointer
      expect(Marshal).to have_received(:dump).with({ 'new.txt' => 300 })
      expect(file_double).to have_received(:write).with([300].pack('L'))
    end
  end
end
