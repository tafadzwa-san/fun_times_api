# typed: false
# frozen_string_literal: true

RSpec.shared_examples 'an adapter initialization' do |adapter_class, *args|
  let(:adapter) { adapter_class.new(*args) }

  context 'when initializing' do
    it 'initializes without error' do
      expect { adapter }.not_to raise_error
    end

    it 'has access to its config' do
      expect(adapter.config).to be_a(Hash)
    end

    it 'has a logger' do
      expect(adapter.logger).to respond_to(:info)
      expect(adapter.logger).to respond_to(:error)
    end
  end
end
