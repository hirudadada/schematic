require 'spec_helper'
require 'schematic/starrocks/templates/naming'

RSpec.describe Schematic::Starrocks::Templates::Naming do
  describe '.generate_routine_name' do
    it 'suffix table name with _rl' do
      expect(described_class.generate_routine_name('example_table')).to eq('example_table_rl')
    end

    it 'handles table names with underscores' do
      expect(described_class.generate_routine_name('my_complex_table')).to eq('my_complex_table_rl')
    end
  end

  describe '.generate_migration_name' do
    let(:table_name) { 'example_table' }
    let(:db_name) { 'schematic' }

    it 'generates name with correct format for create operation' do
      result = described_class.generate_migration_name(table_name, db_name, 'create')
      expect(result).to match(/^\d{14}-create-schematic-example_table-rl$/)
    end

    it 'generates name with correct format for state change operations' do
      %w[pause resume stop].each do |operation|
        result = described_class.generate_migration_name(table_name, db_name, operation)
        expect(result).to match(/^\d{14}-#{operation}-schematic-example_table-rl$/)
      end
    end

    it 'uses provided timestamp' do
      result = described_class.generate_migration_name(table_name, db_name, 'create', 'custom')
      expect(result).to eq('custom-create-schematic-example_table-rl')
    end

    it 'handles table names with underscores' do
      table_name = 'my_complex_table_name'
      result = described_class.generate_migration_name(table_name, db_name, 'create', 'custom')
      expect(result).to eq('custom-create-schematic-my_complex_table_name-rl')
    end
  end

  describe '.extract_info_from_filename' do
    context 'with standard filenames' do
      let(:operations) do
        {
          create: '-create-schematic-example_table-rl.yaml',
          pause: '-pause-schematic-example_table-rl.sql',
          resume: '-resume-schematic-example_table-rl.yaml',
          alter: '-alter-schematic-example_table-rl.yaml',
          stop: '-stop-schematic-example_table-rl.yaml'
        }
      end

      it 'correctly extracts info for all operations' do
        operations.each do |operation, suffix|
          filename = "20241123180700#{suffix}"
          info = described_class.extract_info_from_filename(filename)
          
          expect(info).to include(
            operation: operation.to_s,
            db_name: 'schematic',
            table_name: 'example_table'
          )
          expect(info[:timestamp]).to match(/^\d{14}$/)
        end
      end
    end

    context 'with complex table names' do
      let(:filename) { '20241123180700-create-schematic-my_complex_table_name-rl.yaml' }

      it 'correctly handles table names with multiple underscores' do
        info = described_class.extract_info_from_filename(filename)
        expect(info[:table_name]).to eq('my_complex_table_name')
      end
    end

    context 'with different file extensions' do
      it 'handles .sql files' do
        info = described_class.extract_info_from_filename('20241123180700-create-schematic-example_table-rl.sql')
        expect(info[:table_name]).to eq('example_table')
      end

      it 'handles .yaml files' do
        info = described_class.extract_info_from_filename('20241123180700-create-schematic-example_table-rl.yaml')
        expect(info[:table_name]).to eq('example_table')
      end
    end

    context 'with invalid filenames' do
      it 'raises error for missing parts' do
        expect {
          described_class.extract_info_from_filename('invalid_filename.sql')
        }.to raise_error(StandardError, /Invalid filename format/)
      end

      it 'raises error for wrong suffix' do
        expect {
          described_class.extract_info_from_filename('20241123180700-create-schematic-example_table-wrong-suffix.sql')
        }.to raise_error(StandardError, /Invalid filename format: missing routine-load suffix/)
      end
    end
  end

  describe '.generate_migration_version' do
    it 'generates timestamp in correct format' do
      timestamp = described_class.generate_migration_version
      expect(timestamp).to match(/^\d{14}$/)
    end

    it 'accepts custom timestamp' do
      custom_timestamp = 'custom'
      expect(described_class.generate_migration_version(custom_timestamp)).to eq(custom_timestamp)
    end
  end
end 
