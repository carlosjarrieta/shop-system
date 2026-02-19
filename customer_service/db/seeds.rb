require 'faker'

Customer.destroy_all

50.times do
  Customer.create!(
    name: Faker::Name.unique.name,
    address: Faker::Address.full_address,
    orders_count: rand(0..10)
  )
end

puts "Created #{Customer.count} customers via Faker."
