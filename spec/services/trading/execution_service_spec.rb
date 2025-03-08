# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Trading::ExecutionService do
  subject(:service) { described_class.new(symbol: 'BTC-USDT', action: 'buy', quantity: 0.5, price: nil) }

  let(:binance_mock) do
    instance_double(
      Trading::Adapters::Binance,
      place_order: { source: 'Binance', order_id: '123456', executed_price: 45_000.00, quantity: 0.5, status: 'FILLED' }
    )
  end

  let(:kucoin_mock) do
    instance_double(
      Trading::Adapters::KuCoin,
      place_order: { source: 'KuCoin', order_id: '789012', executed_price: 44_800.00, quantity: 0.5, status: 'FILLED' }
    )
  end

  describe '#execute_trade' do
    context 'when Binance is available and preferred' do
      subject(:service) do
        described_class.new(symbol: 'BTC-USDT', action: 'buy', quantity: 0.5, price: nil, preferred_exchange: 'Binance')
      end

      before do
        allow(Trading::Adapters::Binance).to receive(:new)
          .with('BTC-USDT', 'buy', 0.5, nil).and_return(binance_mock)
      end

      it 'executes the trade on Binance' do
        result = service.execute_trade

        expect(result[:success]).to be true
        expect(result[:trade]).to include(source: 'Binance')
      end
    end

    context 'when KuCoin is available and preferred' do
      subject(:service) do
        described_class.new(symbol: 'BTC-USDT', action: 'buy', quantity: 0.5, price: nil, preferred_exchange: 'KuCoin')
      end

      before do
        allow(Trading::Adapters::KuCoin).to receive(:new)
          .with('BTC-USDT', 'buy', 0.5, nil).and_return(kucoin_mock)
      end

      it 'executes the trade on KuCoin' do
        result = service.execute_trade

        expect(result[:success]).to be true
        expect(result[:trade]).to include(source: 'KuCoin')
      end
    end

    context 'when no exchange is available' do
      before do
        allow(Trading::Adapters::Binance).to receive(:new).and_raise(Errors::BinanceError, 'Binance API Down')
        allow(Trading::Adapters::KuCoin).to receive(:new).and_raise(Errors::KuCoinError, 'KuCoin API Down')
      end

      it 'returns a failure response' do
        result = service.execute_trade

        expect(result[:success]).to be false
        expect(result[:error]).to eq('Trade execution failed: Binance API Down')
      end
    end
  end
end
