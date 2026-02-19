require 'bunny'
require 'json'

namespace :rabbitmq do
  desc "Run consumer for Shop System events"
  task consume: :environment do
    logger = Logger.new(Rails.root.join('log', 'rabbitmq.log'))
    logger.formatter = proc { |severity, datetime, progname, msg| "#{datetime}: #{msg}\n" }
    
    msg = " [*] Waiting for events from 'shop_system.events'. To exit press CTRL+C"
    puts msg
    logger.info(msg)

    host = ENV.fetch('RABBITMQ_HOST', 'localhost')
    user = ENV.fetch('RABBITMQ_USER', 'guest')
    pass = ENV.fetch('RABBITMQ_PASS', 'guest')

    connection = Bunny.new(hostname: host, username: user, password: pass)
    connection.start

    channel = connection.create_channel
    exchange = channel.fanout('shop_system.events')
    queue = channel.queue('customer_service.orders_queue', durable: true)
    queue.bind(exchange)

    begin
      queue.subscribe(block: true) do |delivery_info, properties, body|
        payload = JSON.parse(body)
        routing_key = delivery_info.routing_key
        
        log_msg = " [x] Received '#{routing_key}': #{payload}"
        puts log_msg
        logger.info(log_msg)

        case routing_key
        when 'order.created'
          customer_id = payload['customer_id']
          if customer = Customer.find_by(id: customer_id)
            customer.increment!(:orders_count)
            res_msg = " [v] Updated Customer ##{customer_id} orders_count to #{customer.orders_count}"
            puts res_msg
            logger.info(res_msg)
          else
            err_msg = " [!] Customer ##{customer_id} not found"
            puts err_msg
            logger.error(err_msg)
          end
        else
          logger.warn(" [?] Unknown event type: #{routing_key}")
        end
      end
    rescue Interrupt => _
      connection.close
      logger.info("Connection closed by user")
      exit(0)
    rescue StandardError => e
      logger.error("Fatal error in consumer: #{e.message}")
      logger.error(e.backtrace.join("\n"))
      retry
    end
  end
end
