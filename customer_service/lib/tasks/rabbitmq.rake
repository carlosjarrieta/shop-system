require 'bunny'
require 'json'

namespace :rabbitmq do
  desc "Run consumer for Shop System events"
  task consume: :environment do
    puts " [*] Waiting for events from 'shop_system.events'. To exit press CTRL+C"

    host = ENV.fetch('RABBITMQ_HOST', 'localhost')
    user = ENV.fetch('RABBITMQ_USER', 'guest')
    pass = ENV.fetch('RABBITMQ_PASS', 'guest')

    connection = Bunny.new(hostname: host, username: user, password: pass)
    connection.start

    channel = connection.create_channel

    # Exchange (must match Publisher)
    exchange = channel.fanout('shop_system.events')

    # Queue (Unique to this service)
    queue = channel.queue('customer_service.orders_queue', durable: true)

    # Bind queue to exchange (Subscribe)
    queue.bind(exchange)

    begin
      queue.subscribe(block: true) do |delivery_info, properties, body|
        payload = JSON.parse(body)
        routing_key = delivery_info.routing_key
        
        puts " [x] Received '#{routing_key}': #{payload}"

        case routing_key
        when 'order.created'
          # Consumer Logic - Strategy Pattern could be used here for multiple events
          customer_id = payload['customer_id']
          if customer = Customer.find_by(id: customer_id)
            customer.increment!(:orders_count)
            puts " [v] Updated Customer ##{customer_id} orders_count to #{customer.orders_count}"
          else
            puts " [!] Customer ##{customer_id} not found"
          end
        else
          puts " [?] Unknown event type"
        end
      end
    rescue Interrupt => _
      connection.close
      puts "Connection closed"
      exit(0)
    end
  end
end
