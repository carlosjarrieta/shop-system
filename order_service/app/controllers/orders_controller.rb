class OrdersController < ApplicationController
  def index
    # Filter by customer_id if provided (as per requirements)
    if params[:customer_id]
      @orders = Order.where(customer_id: params[:customer_id])
    else
      @orders = Order.all
    end
    render json: @orders
  end

  def create
    service = CreateOrderService.new(order_params)
    result = service.call

    if result[:success]
      render json: result[:order], status: :created
    else
      render json: { errors: result[:errors] }, status: :unprocessable_entity
    end
  end

  private

  def order_params
    params.require(:order).permit(:customer_id, :product_name, :quantity, :price)
  end
end
