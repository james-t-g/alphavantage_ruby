# frozen_string_literal: true

require 'date'

module Alphavantage
  module Validations
    VALID_SLICES = (1..2).map do |year|
      (1..12).map do |month|
        "year#{year}month#{month}"
      end
    end.flatten.map(&:to_sym)

    VALID_INTERVALS = %i{ 1min 5min 15min 30min 60min }
    VALID_INDICATOR_INTERVALS = VALID_INTERVALS + %i{ daily weekly monthly }
    VALID_OUTPUTSIZES = %i{ compact full }
    VALID_SERIES_TYPES = %i{ close open high low }
    VALID_DATATYPES = %i{ json csv }
    VALID_MINIMUM_OPTIONS_DATE = Date.parse('2008-01-01')

    private

    def validate_slice(value)
      validate_from_collection(value: value, collection: VALID_SLICES, type: 'slice')
    end

    def validate_interval(value)
      validate_from_collection(value: value, collection: VALID_INTERVALS, type: 'interval')
    end

    def validate_outputsize(value)
      validate_from_collection(value: value, collection: VALID_OUTPUTSIZES, type: 'outputsize')
    end

    def validate_indicator_interval(value)
      validate_from_collection(value: value, collection: VALID_INDICATOR_INTERVALS, type: 'interval')
    end

    def validate_series_type(value)
      validate_from_collection(value: value, collection: VALID_SERIES_TYPES, type: 'series type')
    end

    def validate_datatype(value)
      validate_from_collection(value: value, collection: VALID_DATATYPES, type: 'data type')
    end

    def validate_integer(label:,value:)
      raise Alphavantage::Error, "Invalid #{label} given. Must be integer." unless is_integer?(value)
      value
    end

    def validate_mat(moving_average_type)
      raise Alphavantage::Error, "Invalid moving average type given." if !(0..8).include?(moving_average_type)
      moving_average_type
    end

    # the validate options contract format is IBM250725C00135000
    def validate_options_contract(value)
      return value if value.nil?
      raise Alphavantage::Error, "Invalid options contract given. Must be in format IBM250725C00135000." \
        unless !value.empty? && value =~ /^[A-Z]{1,5}\d{6}[CP]\d{8}$/ 
      value
    end

    # the validate options date format is YYYY-MM-DD
    # and must be greater than 2008-01-01
    def validate_options_date(value)
      return value if value.nil?
      raise Alphavantage::Error, "Invalid date given. Must be in format YYYY-MM-DD." unless value =~ /^\d{4}-\d{2}-\d{2}$/
      
      begin
        parsed_date = Date.parse(value)
        raise Alphavantage::Error, "Invalid date given. Must be greater than #{VALID_MINIMUM_OPTIONS_DATE.strftime("%Y-%m-%d")}." \
          unless parsed_date >= VALID_MINIMUM_OPTIONS_DATE
      rescue Date::Error
        raise Alphavantage::Error, "Invalid date given. Must be in format YYYY-MM-DD."
      end
      
      value
    end

    def is_integer?(str)
      Integer(str) rescue false
    end

    private

    def validate_from_collection(value:, collection:, type:)
      return value if collection.include?(value.to_sym)

      message = "Invalid #{type} given. Given #{value}, allowed: #{collection.map{|c| "'#{c}'"}.join(', ')}"
      raise Alphavantage::Error, message
    end
  end
end