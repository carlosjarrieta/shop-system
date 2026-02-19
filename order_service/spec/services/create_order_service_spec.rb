require 'rails_helper'
require 'webmock/rspec'

RSpec.describe CreateOrderService do
  let(:customer_id) { 1 }
  let(:params) do
    {
      customer_id: customer_id,
      product_name: 'Test Product',
      quantity: 1,
      price: 100.0
    }
  end

  subject { described_class.new(params) }

  describe '#call' do
    let(:base_url) { ENV.fetch('CUSTOMER_SERVICE_URL', 'http://localhost:3000') }

    context 'when customer exists in customer_service' do
      before do
        # Mock de la respuesta exitosa usando la URL configurada
        stub_request(:get, "#{base_url}/customers/#{customer_id}")
          .to_return(status: 200, body: { id: customer_id, name: 'John Doe' }.to_json)
        
        # Mock de RabbitMQ para evitar conexiones reales durante el test
        allow(EventPublisher).to receive(:publish).and_return(true)
      end

      it 'creates a new order with pending status' do
        expect { subject.call }.to change(Order, :count).by(1)
        expect(Order.last.status).to eq('pending')
      end

      it 'publishes an order.created event' do
        subject.call
        expect(EventPublisher).to have_received(:publish).with('order.created', anything)
      end
    end

    context 'when customer does not exist' do
      before do
        stub_request(:get, "#{base_url}/customers/#{customer_id}")
          .to_return(status: 404)
      end

      it 'returns success false and does not create an order' do
        result = subject.call
        expect(result[:success]).to be false
        expect(result[:errors]).to include('Customer not found')
        expect(Order.count).to eq(0)
      end
    end
  end
end
