class CreateOrderService
  include ActiveModel::Validations

  attr_reader :params, :customer, :order

  # Metaprogramación: Definimos dinámicamente los métodos de acceso a params
  # Esto cumple con el principio DRY y demuestra el poder de Ruby
  [:customer_id, :product_name, :quantity, :price].each do |attr|
    define_method(attr) { params[attr] }
  end

  validates :customer_id, :product_name, :quantity, :price, presence: true

  def initialize(params)
    @params = params
    @customer_id = params[:customer_id]
  end

  def call
    return { success: false, errors: errors.full_messages } unless valid?

    # 1. Validate Customer via Gateway (Sync)
    customer_client = CustomerServiceClient.new
    customer_data = customer_client.find_customer(@customer_id)

    if customer_data.nil?
      return { success: false, errors: ["Customer not found"] }
    end

    # 2. Persist Order (Command)
    @order = Order.new(params)

    if @order.save
      # 3. Publish Event (EDA) - Async
      EventPublisher.publish('order.created', {
        order_id: @order.id,
        customer_id: @order.customer_id,
        amount: @order.price
      })

      { success: true, order: @order }
    else
      { success: false, errors: @order.errors.full_messages }
    end
  rescue StandardError => e
    Rails.logger.error("Order Creation Failed: #{e.message}")
    { success: false, errors: ["System Error: #{e.message}"] }
  end
end
