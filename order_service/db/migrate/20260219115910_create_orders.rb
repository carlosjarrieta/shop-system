class CreateOrders < ActiveRecord::Migration[7.2]
  def change
    create_table :orders do |t|
      t.integer :customer_id, index: true
      t.string :product_name
      t.integer :quantity
      t.decimal :price, precision: 10, scale: 2
      t.string :status, default: 'pending'

      t.timestamps
    end
  end
end
