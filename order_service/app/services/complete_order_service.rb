class CompleteOrderService
  def self.call(payload)
    new(payload).call
  end

  def initialize(payload)
    @payload = payload
  end

  def call
    order_id = @payload['order_id']
    order = Order.find_by(id: order_id)

    if order
      order.update(status: 'completed')
      { success: true, order: order }
    else
      { success: false, error: "Order ##{order_id} not found" }
    end
  rescue StandardError => e
    Rails.logger.error("Error in CompleteOrderService: #{e.message}")
    { success: false, error: e.message }
  end
end
