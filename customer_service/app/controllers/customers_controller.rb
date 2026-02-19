class CustomersController < ApplicationController
  def show
    customer = Customer.find(params[:id])
    render json: customer
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Customer not found' }, status: :not_found
  end
end
