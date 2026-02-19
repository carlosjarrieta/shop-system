class UpdateCustomerOrdersService
  def self.call(payload)
    new(payload).call
  end

  attr_reader :payload

  # Metaprogramación: Definimos dinámicamente los métodos de acceso a payload
  [:customer_id].each do |attr|
    define_method(attr) { payload[attr.to_s] || payload[attr.to_sym] }
  end

  def initialize(payload)
    @payload = payload
  end

  def call
    customer = Customer.find_by(id: customer_id)

    if customer
      customer.increment!(:orders_count)
      
      # Feedback Loop: Notificamos de vuelta al Order Service que el proceso terminó
      EventPublisher.publish('order.processed', { order_id: @payload['order_id'] })
      
      { success: true, customer: customer }
    else
      { success: false, error: "Customer ##{customer_id} not found" }
    end
  rescue StandardError => e
    Rails.logger.error("Error in UpdateCustomerOrdersService: #{e.message}")
    { success: false, error: e.message }
  end
end
