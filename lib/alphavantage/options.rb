module Alphavantage
  class Options
    include Validations

    FUNCTIONS = {
      realtime_options: 'REALTIME_OPTIONS',
      historical_options: 'HISTORICAL_OPTIONS'
    }

    def initialize(symbol:)
      @symbol = symbol
    end

    def realtime_options(require_greeks: false, contract: nil)
      Client.get(params: { function: FUNCTIONS[__method__], 
          symbol: @symbol, 
          require_greeks: require_greeks, 
          contract: validate_options_contract(contract)
      })
    end

    def historical_options(date: nil)
      Client.get(params: { function: FUNCTIONS[__method__], 
        symbol: @symbol, 
        date: validate_options_date(date)
    })
    end
  end
end