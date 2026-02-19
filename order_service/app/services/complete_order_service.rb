class CompleteOrderService
  def self.call(payload)
    new(payload).call
  end

  def initialize(payload)
    @payload = payload
  end

  def call
    order_id = @payload['order_id']

    return { success: false, error: "order_id is required" } unless order_id

    order = Order.find_by(id: order_id)

    return { success: false, error: "Order ##{order_id} not found" } unless order

    order.update(status: 'completed')
    { success: true, order: order }
  rescue StandardError => e
    Rails.logger.error("Error in CompleteOrderService: #{e.message}")
    { success: false, error: e.message }
  end
end