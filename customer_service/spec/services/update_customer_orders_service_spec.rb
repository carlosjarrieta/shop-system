require 'rails_helper'

RSpec.describe UpdateCustomerOrdersService do
  let!(:customer) { Customer.create!(name: 'Test Customer', address: '123 St', orders_count: 5) }
  let(:payload) { { 'customer_id' => customer.id, 'order_id' => 123 } }

  subject { described_class.new(payload) }

  describe '#call' do
    before do
      # Mock de RabbitMQ para el feedback loop
      allow(EventPublisher).to receive(:publish).and_return(true)
    end

    it 'increments the customer orders_count' do
      expect { subject.call }.to change { customer.reload.orders_count }.by(1)
    end

    it 'publishes an order.processed feedback event' do
      subject.call
      expect(EventPublisher).to have_received(:publish).with('order.processed', { order_id: 123 })
    end

    context 'when customer does not exist' do
      let(:payload) { { 'customer_id' => 9999, 'order_id' => 123 } }

      it 'returns error and does not crash' do
        result = subject.call
        expect(result[:success]).to be false
        expect(result[:error]).to include('not found')
      end
    end
  end
end
