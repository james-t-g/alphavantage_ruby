require 'spec_helper'

RSpec.describe Alphavantage::Validations do
  # Create a test class that includes the Validations module to access private methods
  let(:test_class) do
    Class.new do
      include Alphavantage::Validations
      
      # Make private methods public for testing
      public :validate_slice, :validate_interval, :validate_outputsize, :validate_indicator_interval,
             :validate_series_type, :validate_datatype, :validate_integer, :validate_mat,
             :validate_options_contract, :validate_options_date, :is_integer?
    end
  end
  
  let(:validator) { test_class.new }

  describe 'constants' do
    it 'defines VALID_SLICES correctly' do
      expect(described_class::VALID_SLICES).to include(:year1month1, :year1month12, :year2month1, :year2month12)
      expect(described_class::VALID_SLICES.size).to eq(24) # 2 years * 12 months
    end

    it 'defines VALID_INTERVALS' do
      expect(described_class::VALID_INTERVALS).to eq(%i{1min 5min 15min 30min 60min})
    end

    it 'defines VALID_INDICATOR_INTERVALS' do
      expected = %i{1min 5min 15min 30min 60min daily weekly monthly}
      expect(described_class::VALID_INDICATOR_INTERVALS).to eq(expected)
    end

    it 'defines other valid constants' do
      expect(described_class::VALID_OUTPUTSIZES).to eq(%i{compact full})
      expect(described_class::VALID_SERIES_TYPES).to eq(%i{close open high low})
      expect(described_class::VALID_DATATYPES).to eq(%i{json csv})
      expect(described_class::VALID_MINIMUM_OPTIONS_DATE).to eq(Date.parse('2008-01-01'))
    end
  end

  describe '#validate_slice' do
    it 'accepts valid slice symbols' do
      expect(validator.validate_slice(:year1month1)).to eq(:year1month1)
      expect(validator.validate_slice(:year2month12)).to eq(:year2month12)
    end

    it 'accepts valid slice strings that convert to symbols' do
      expect(validator.validate_slice('year1month6')).to eq('year1month6')
    end

    it 'raises error for invalid slice' do
      expect { validator.validate_slice(:invalid_slice) }
        .to raise_error(Alphavantage::Error, /Invalid slice given/)
    end
  end

  describe '#validate_interval' do
    it 'accepts valid intervals' do
      %i{1min 5min 15min 30min 60min}.each do |interval|
        expect(validator.validate_interval(interval)).to eq(interval)
      end
    end

    it 'accepts string intervals' do
      expect(validator.validate_interval('5min')).to eq('5min')
    end

    it 'raises error for invalid interval' do
      expect { validator.validate_interval(:invalid) }
        .to raise_error(Alphavantage::Error, /Invalid interval given/)
    end
  end

  describe '#validate_outputsize' do
    it 'accepts valid outputsizes' do
      expect(validator.validate_outputsize(:compact)).to eq(:compact)
      expect(validator.validate_outputsize(:full)).to eq(:full)
    end

    it 'raises error for invalid outputsize' do
      expect { validator.validate_outputsize(:invalid) }
        .to raise_error(Alphavantage::Error, /Invalid outputsize given/)
    end
  end

  describe '#validate_indicator_interval' do
    it 'accepts all valid indicator intervals' do
      %i{1min 5min 15min 30min 60min daily weekly monthly}.each do |interval|
        expect(validator.validate_indicator_interval(interval)).to eq(interval)
      end
    end

    it 'raises error for invalid indicator interval' do
      expect { validator.validate_indicator_interval(:invalid) }
        .to raise_error(Alphavantage::Error, /Invalid interval given/)
    end
  end

  describe '#validate_series_type' do
    it 'accepts valid series types' do
      %i{close open high low}.each do |type|
        expect(validator.validate_series_type(type)).to eq(type)
      end
    end

    it 'raises error for invalid series type' do
      expect { validator.validate_series_type(:invalid) }
        .to raise_error(Alphavantage::Error, /Invalid series type given/)
    end
  end

  describe '#validate_datatype' do
    it 'accepts valid datatypes' do
      expect(validator.validate_datatype(:json)).to eq(:json)
      expect(validator.validate_datatype(:csv)).to eq(:csv)
    end

    it 'raises error for invalid datatype' do
      expect { validator.validate_datatype(:invalid) }
        .to raise_error(Alphavantage::Error, /Invalid data type given/)
    end
  end

  describe '#validate_integer' do
    it 'accepts valid integer strings' do
      expect(validator.validate_integer(label: 'test', value: '123')).to eq('123')
      expect(validator.validate_integer(label: 'test', value: '0')).to eq('0')
      expect(validator.validate_integer(label: 'test', value: '-5')).to eq('-5')
    end

    it 'accepts integer objects' do
      expect(validator.validate_integer(label: 'test', value: 123)).to eq(123)
    end

    it 'raises error for non-integer strings' do
      expect { validator.validate_integer(label: 'time period', value: 'abc') }
        .to raise_error(Alphavantage::Error, 'Invalid time period given. Must be integer.')
    end

    it 'raises error for decimal strings' do
      expect { validator.validate_integer(label: 'count', value: '12.5') }
        .to raise_error(Alphavantage::Error, 'Invalid count given. Must be integer.')
    end
  end

  describe '#validate_mat' do
    it 'accepts valid moving average types (0-8)' do
      (0..8).each do |mat|
        expect(validator.validate_mat(mat)).to eq(mat)
      end
    end

    it 'raises error for values below 0' do
      expect { validator.validate_mat(-1) }
        .to raise_error(Alphavantage::Error, 'Invalid moving average type given.')
    end

    it 'raises error for values above 8' do
      expect { validator.validate_mat(9) }
        .to raise_error(Alphavantage::Error, 'Invalid moving average type given.')
    end
  end

  describe '#validate_options_contract' do
    it 'returns nil for nil input' do
      expect(validator.validate_options_contract(nil)).to be_nil
    end

    it 'accepts valid options contract formats' do
      valid_contracts = [
        'IBM250725C00135000',     # Call option
        'AAPL250725P00150000',    # Put option
        'GOOGL250725C02500000',   # High strike call
        'TSLA250725P00100000',    # Put option
        'A250725C00050000'        # Single letter symbol
      ]

      valid_contracts.each do |contract|
        expect(validator.validate_options_contract(contract)).to eq(contract)
      end
    end

    it 'raises error for empty contract' do
      expect { validator.validate_options_contract('') }
        .to raise_error(Alphavantage::Error, /Invalid options contract given/)
    end

    it 'raises error for invalid contract formats' do
      invalid_contracts = [
        'ibm250725c00135000',     # lowercase symbol
        'IBM25072500135000',      # missing C/P
        'IBM250725X00135000',     # invalid option type (X)
        'IBM250725C0135000',      # wrong strike format
        'IBM25725C00135000',      # wrong date format
        'TOOLONG250725C00135000', # symbol too long
        'IBM250725C001350001'     # strike too long
      ]

      invalid_contracts.each do |contract|
        expect { validator.validate_options_contract(contract) }
          .to raise_error(Alphavantage::Error, /Invalid options contract given/)
      end
    end
  end

  describe '#validate_options_date' do
    it 'returns nil for nil input' do
      expect(validator.validate_options_date(nil)).to be_nil
    end

    it 'accepts valid dates after minimum date' do
      valid_dates = [
        '2008-01-01',   # Minimum date itself
        '2008-01-02',   # Day after minimum
        '2010-06-15',   # Random valid date
        '2025-12-31'    # Future date
      ]

      valid_dates.each do |date|
        expect(validator.validate_options_date(date)).to eq(date)
      end
    end

    it 'raises error for dates before minimum date' do
      invalid_dates = [
        '2007-12-31',   # Day before minimum
        '2000-01-01',   # Much earlier
        '1999-12-25'    # Even earlier
      ]

      invalid_dates.each do |date|
        expect { validator.validate_options_date(date) }
          .to raise_error(Alphavantage::Error, /Invalid date given.*Must be greater than 2008-01-01/)
      end
    end

    it 'raises error for invalid date formats' do
      invalid_formats = [
        '2008/01/02',   # Wrong separator
        '01-02-2008',   # Wrong order
        '2008-1-2',     # Missing leading zeros
        '08-01-02',     # Two-digit year
        'Jan 2, 2008',  # Text format
        '2008-13-01',   # Invalid month
        '2008-01-32',   # Invalid day
        'invalid'       # Not a date
      ]

      invalid_formats.each do |date|
        expect { validator.validate_options_date(date) }
          .to raise_error(Alphavantage::Error, /Invalid date given.*Must be in format YYYY-MM-DD/)
      end
    end
  end

  describe '#is_integer?' do
    it 'returns truthy for integer strings' do
      expect(validator.is_integer?('123')).to be_truthy
      expect(validator.is_integer?('0')).to be_truthy
      expect(validator.is_integer?('-5')).to be_truthy
    end

    it 'returns truthy for integer objects' do
      expect(validator.is_integer?(123)).to be_truthy
      expect(validator.is_integer?(0)).to be_truthy
      expect(validator.is_integer?(-5)).to be_truthy
    end

    it 'returns falsy for non-integers' do
      expect(validator.is_integer?('abc')).to be_falsy
      expect(validator.is_integer?('12.5')).to be_falsy
      expect(validator.is_integer?('')).to be_falsy
      expect(validator.is_integer?(nil)).to be_falsy
    end
  end
end
