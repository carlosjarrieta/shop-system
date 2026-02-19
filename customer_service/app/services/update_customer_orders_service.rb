class UpdateCustomerOrdersService
  def self.call(payload)
    new(payload).call
  end

  def initialize(payload)
    @payload = payload
  end

  def call
    customer_id = @payload['customer_id']
    customer = Customer.find_by(id: customer_id)

    if customer
      customer.increment!(:orders_count)
      { success: true, customer: customer }
    else
      { success: false, error: "Customer ##{customer_id} not found" }
    end
  rescue StandardError => e
    Rails.logger.error("Error in UpdateCustomerOrdersService: #{e.message}")
    { success: false, error: e.message }
  end
end
