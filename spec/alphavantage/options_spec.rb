require 'spec_helper'

RSpec.describe Alphavantage::Options do
  let(:options) { described_class.new(symbol: 'IBM') }

  before do
    Alphavantage.configure do |config|
      config.api_key = 'demo'
    end
  end

  describe '#realtime_options' do
    context 'with basic parameters' do
      let(:expected_params) do
        {
          function: 'REALTIME_OPTIONS',
          symbol: 'IBM',
          require_greeks: false,
          contract: nil,
          apikey: 'demo'
        }
      end

      before do
        stub_request(:get, 'https://www.alphavantage.co/query')
          .with(query: expected_params)
          .to_return(
            status: 200,
            body: File.read('spec/fixtures/options/realtime_options.json'),
            headers: { 'Content-Type' => 'application/json' }
          )
      end

      subject { options.realtime_options }

      it 'makes correct API request' do
        subject
        expect(WebMock).to have_requested(:get, 'https://www.alphavantage.co/query')
          .with(query: expected_params)
      end

      it 'returns response with correct structure' do
        expect(subject.endpoint).to eq('Realtime Options')
        expect(subject.message).to eq('success')
        expect(subject.data).to be_an(Array)
        expect(subject.data).not_to be_empty
      end

      it 'returns options data with correct attributes' do
        first_option = subject.data.first
        
        expect(first_option.contract_id).to eq('IBM250725C00135000')
        expect(first_option.symbol).to eq('IBM')
        expect(first_option.expiration).to eq('2025-07-25')
        expect(first_option.strike).to eq('135.00')
        expect(first_option.type).to eq('call')
        expect(first_option.last).to eq('0.00')
        expect(first_option.mark).to eq('147.50')
        expect(first_option.bid).to eq('146.35')
        expect(first_option.bid_size).to eq('4')
        expect(first_option.ask).to eq('148.65')
        expect(first_option.ask_size).to eq('2')
        expect(first_option.volume).to eq('0')
        expect(first_option.open_interest).to eq('0')
        expect(first_option.date).to eq('2025-07-22')
      end

      it 'does not include greek values' do
        first_option = subject.data.first
        expect(first_option).not_to respond_to(:implied_volatility)
        expect(first_option).not_to respond_to(:delta)
        expect(first_option).not_to respond_to(:gamma)
        expect(first_option).not_to respond_to(:theta)
        expect(first_option).not_to respond_to(:vega)
        expect(first_option).not_to respond_to(:rho)
      end
    end

    context 'with require_greeks: true' do
      let(:expected_params) do
        {
          function: 'REALTIME_OPTIONS',
          symbol: 'AAPL',
          require_greeks: true,
          contract: nil,
          apikey: 'demo'
        }
      end

      before do
        stub_request(:get, 'https://www.alphavantage.co/query')
          .with(query: expected_params)
          .to_return(
            status: 200,
            body: File.read('spec/fixtures/options/realtime_options_greeks.json'),
            headers: { 'Content-Type' => 'application/json' }
          )
      end

      subject { described_class.new(symbol: 'AAPL').realtime_options(require_greeks: true) }

      it 'makes correct API request' do
        subject
        expect(WebMock).to have_requested(:get, 'https://www.alphavantage.co/query')
          .with(query: expected_params)
      end

      it 'returns options data with greek values' do
        first_option = subject.data.first
        
        expect(first_option.implied_volatility).to eq('4.27331')
        expect(first_option.delta).to eq('0.98183')
        expect(first_option.gamma).to eq('0.00041')
        expect(first_option.theta).to eq('-0.82695')
        expect(first_option.vega).to eq('0.01140')
        expect(first_option.rho).to eq('0.01060')
      end
    end

    context 'with specific contract' do
      let(:contract) { 'IBM250725C00135000' }
      let(:expected_params) do
        {
          function: 'REALTIME_OPTIONS',
          symbol: 'IBM',
          require_greeks: false,
          contract: contract,
          apikey: 'demo'
        }
      end

      before do
        stub_request(:get, 'https://www.alphavantage.co/query')
          .with(query: expected_params)
          .to_return(
            status: 200,
            body: File.read('spec/fixtures/options/realtime_options_contract.json'),
            headers: { 'Content-Type' => 'application/json' }
          )
      end

      subject { options.realtime_options(contract: contract) }

      it 'makes correct API request with contract parameter' do
        subject
        expect(WebMock).to have_requested(:get, 'https://www.alphavantage.co/query')
          .with(query: expected_params)
      end

      it 'returns single contract data' do
        expect(subject.data).to be_an(Array)
        expect(subject.data.size).to eq(1)
        expect(subject.data.first.contract_id).to eq(contract)
      end
    end

    context 'with contract and greeks' do
      let(:contract) { 'IBM250725C00135000' }
      let(:expected_params) do
        {
          function: 'REALTIME_OPTIONS',
          symbol: 'IBM',
          require_greeks: true,
          contract: contract,
          apikey: 'demo'
        }
      end

      before do
        stub_request(:get, 'https://www.alphavantage.co/query')
          .with(query: expected_params)
          .to_return(
            status: 200,
            body: File.read('spec/fixtures/options/realtime_options_contract_greeks.json'),
            headers: { 'Content-Type' => 'application/json' }
          )
      end

      subject { options.realtime_options(contract: contract, require_greeks: true) }

      it 'makes correct API request with both parameters' do
        subject
        expect(WebMock).to have_requested(:get, 'https://www.alphavantage.co/query')
          .with(query: expected_params)
      end

      it 'returns single contract data with greeks' do
        first_option = subject.data.first
        
        expect(first_option.contract_id).to eq(contract)
        expect(first_option.implied_volatility).not_to be_nil
        expect(first_option.delta).not_to be_nil
        expect(first_option.gamma).not_to be_nil
        expect(first_option.theta).not_to be_nil
        expect(first_option.vega).not_to be_nil
        expect(first_option.rho).not_to be_nil
      end
    end

    context 'with nil contract' do
      let(:expected_params) do
        {
          function: 'REALTIME_OPTIONS',
          symbol: 'TSLA',
          require_greeks: false,
          contract: nil,
          apikey: 'demo'
        }
      end

      before do
        stub_request(:get, 'https://www.alphavantage.co/query')
          .with(query: expected_params)
          .to_return(
            status: 200,
            body: File.read('spec/fixtures/options/realtime_options.json'),
            headers: { 'Content-Type' => 'application/json' }
          )
      end

      subject { described_class.new(symbol: 'TSLA').realtime_options(contract: nil) }

      it 'makes correct API request with nil contract' do
        subject
        expect(WebMock).to have_requested(:get, 'https://www.alphavantage.co/query')
          .with(query: expected_params)
      end
    end
  end

  describe '#historical_options' do
    context 'with basic parameters' do
      let(:expected_params) do
        {
          function: 'HISTORICAL_OPTIONS',
          symbol: 'IBM',
          date: nil,
          apikey: 'demo'
        }
      end

      before do
        stub_request(:get, 'https://www.alphavantage.co/query')
          .with(query: expected_params)
          .to_return(
            status: 200,
            body: File.read('spec/fixtures/options/historical_options.json'),
            headers: { 'Content-Type' => 'application/json' }
          )
      end

      subject { options.historical_options }

      it 'makes correct API request' do
        subject
        expect(WebMock).to have_requested(:get, 'https://www.alphavantage.co/query')
          .with(query: expected_params)
      end

      it 'returns response with correct structure' do
        expect(subject.endpoint).to eq('Historical Options')
        expect(subject.message).to eq('success')
        expect(subject.data).to be_an(Array)
        expect(subject.data).not_to be_empty
      end

      it 'returns historical options data with correct attributes' do
        first_option = subject.data.first
        
        expect(first_option.contract_id).to eq('IBM250725C00135000')
        expect(first_option.symbol).to eq('IBM')
        expect(first_option.expiration).to eq('2025-07-25')
        expect(first_option.strike).to eq('135.00')
        expect(first_option.type).to eq('call')
        expect(first_option.last).to eq('0.00')
        expect(first_option.mark).to eq('150.35')
        expect(first_option.bid).to eq('149.05')
        expect(first_option.bid_size).to eq('48')
        expect(first_option.ask).to eq('151.65')
        expect(first_option.ask_size).to eq('10')
        expect(first_option.volume).to eq('0')
        expect(first_option.open_interest).to eq('0')
        expect(first_option.date).to eq('2025-07-21')
      end

      it 'includes historical greek values' do
        first_option = subject.data.first
        
        expect(first_option.implied_volatility).to eq('3.53187')
        expect(first_option.delta).to eq('0.98625')
        expect(first_option.gamma).to eq('0.00033')
        expect(first_option.theta).to eq('-0.47781')
        expect(first_option.vega).to eq('0.01047')
        expect(first_option.rho).to eq('0.01430')
      end
    end

    context 'with specific date' do
      let(:date) { '2025-01-02' }
      let(:expected_params) do
        {
          function: 'HISTORICAL_OPTIONS',
          symbol: 'IBM',
          date: date,
          apikey: 'demo'
        }
      end

      before do
        stub_request(:get, 'https://www.alphavantage.co/query')
          .with(query: expected_params)
          .to_return(
            status: 200,
            body: File.read('spec/fixtures/options/historical_options_date.json'),
            headers: { 'Content-Type' => 'application/json' }
          )
      end

      subject { options.historical_options(date: date) }

      it 'makes correct API request with date parameter' do
        subject
        expect(WebMock).to have_requested(:get, 'https://www.alphavantage.co/query')
          .with(query: expected_params)
      end

      it 'returns data for the specific date' do
        first_option = subject.data.first
        expect(first_option.date).to eq('2025-01-02')
        expect(first_option.contract_id).to eq('IBM250103C00120000')
      end

      it 'returns options with different expiration dates' do
        first_option = subject.data.first
        expect(first_option.expiration).to eq('2025-01-03')
      end
    end

    context 'with nil date' do
      let(:expected_params) do
        {
          function: 'HISTORICAL_OPTIONS',
          symbol: 'AAPL',
          date: nil,
          apikey: 'demo'
        }
      end

      before do
        stub_request(:get, 'https://www.alphavantage.co/query')
          .with(query: expected_params)
          .to_return(
            status: 200,
            body: File.read('spec/fixtures/options/historical_options.json'),
            headers: { 'Content-Type' => 'application/json' }
          )
      end

      subject { described_class.new(symbol: 'AAPL').historical_options(date: nil) }

      it 'makes correct API request with nil date' do
        subject
        expect(WebMock).to have_requested(:get, 'https://www.alphavantage.co/query')
          .with(query: expected_params)
      end
    end
  end

  describe 'error handling' do
    context 'API error response' do
      let(:error_body) do
        {
          "Error Message" => "Invalid API call. Please retry or visit the documentation for proper API structure."
        }.to_json
      end

      before do
        stub_request(:get, 'https://www.alphavantage.co/query')
          .with(query: hash_including({
            function: 'REALTIME_OPTIONS',
            symbol: 'INVALID',
            apikey: 'demo'
          }))
          .to_return(
            status: 200,
            body: error_body,
            headers: { 'Content-Type' => 'application/json' }
          )
        
        stub_request(:get, 'https://www.alphavantage.co/query')
          .with(query: hash_including({
            function: 'HISTORICAL_OPTIONS',
            symbol: 'INVALID',
            apikey: 'demo'
          }))
          .to_return(
            status: 200,
            body: error_body,
            headers: { 'Content-Type' => 'application/json' }
          )
      end

      it 'raises Alphavantage::Error for realtime_options' do
        expect {
          described_class.new(symbol: 'INVALID').realtime_options
        }.to raise_error(Alphavantage::Error)
      end

      it 'raises Alphavantage::Error for historical_options' do
        expect {
          described_class.new(symbol: 'INVALID').historical_options
        }.to raise_error(Alphavantage::Error)
      end
    end

    context 'HTTP error response' do
      before do
        stub_request(:get, 'https://www.alphavantage.co/query')
          .with(query: hash_including({
            function: 'REALTIME_OPTIONS',
            symbol: 'IBM',
            apikey: 'demo'
          }))
          .to_return(status: 500, body: 'Internal Server Error')
        
        stub_request(:get, 'https://www.alphavantage.co/query')
          .with(query: hash_including({
            function: 'HISTORICAL_OPTIONS',
            symbol: 'IBM',
            apikey: 'demo'
          }))
          .to_return(status: 500, body: 'Internal Server Error')
      end

      it 'raises Alphavantage::Error for realtime_options' do
        expect {
          options.realtime_options
        }.to raise_error(Alphavantage::Error, /Response status: 500/)
      end

      it 'raises Alphavantage::Error for historical_options' do
        expect {
          options.historical_options
        }.to raise_error(Alphavantage::Error, /Response status: 500/)
      end
    end
  end

  describe 'data transformation' do
    before do
      stub_request(:get, 'https://www.alphavantage.co/query')
        .with(query: {
          function: 'REALTIME_OPTIONS',
          symbol: 'IBM',
          require_greeks: false,
          contract: nil,
          apikey: 'demo'
        })
        .to_return(
          status: 200,
          body: File.read('spec/fixtures/options/realtime_options.json'),
          headers: { 'Content-Type' => 'application/json' }
        )
    end

    subject { options.realtime_options }

    it 'converts keys to accessible attributes' do
      first_option = subject.data.first
      
      # Test that snake_case conversion happened
      expect(first_option.contract_id).to eq('IBM250725C00135000')
      expect(first_option.bid_size).to eq('4')
      expect(first_option.ask_size).to eq('2')
      expect(first_option.open_interest).to eq('0')
    end

    it 'makes response accessible as hash-like object' do
      # Test Hashie::Mash behavior
      expect(subject['endpoint']).to eq('Realtime Options')
      expect(subject[:message]).to eq('success')
      expect(subject.data[0]['symbol']).to eq('IBM')
        expect(subject.data[0][:contract_id]).to eq('IBM250725C00135000')
    end
  end
end
