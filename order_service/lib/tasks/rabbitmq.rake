require 'bunny'
require 'json'

namespace :rabbitmq do
  desc "Run consumer for Order Service response events"
  task consume_responses: :environment do
    logger = Logger.new(Rails.root.join('log', 'rabbitmq_responses.log'))
    logger.formatter = proc { |severity, datetime, progname, msg| "#{datetime}: #{msg}\n" }
    
    msg = " [*] Waiting for responses from 'shop_system.events'. To exit press CTRL+C"
    puts msg
    logger.info(msg)

    host = ENV.fetch('RABBITMQ_HOST', 'localhost')
    user = ENV.fetch('RABBITMQ_USER', 'guest')
    pass = ENV.fetch('RABBITMQ_PASS', 'guest')

    connection = Bunny.new(hostname: host, username: user, password: pass)
    connection.start

    channel = connection.create_channel
    exchange = channel.fanout('shop_system.events')

    # Queue específica para el Order Service
    queue = channel.queue('order_service.responses_queue', durable: true)
    queue.bind(exchange)

    begin
      queue.subscribe(block: true) do |delivery_info, properties, body|
        payload = JSON.parse(body)
        routing_key = delivery_info.routing_key
        
        case routing_key
        when 'order.processed'
          log_msg = " [x] Received feedback for Order ##{payload['order_id']}"
          puts log_msg
          logger.info(log_msg)

          result = CompleteOrderService.call(payload)
          
          if result[:success]
            res_msg = " [v] Order ##{payload['order_id']} marked as COMPLETED"
            puts res_msg
            logger.info(res_msg)
          else
            err_msg = " [!] Error completing order: #{result[:error]}"
            puts err_msg
            logger.error(err_msg)
          end
        end
      end
    rescue Interrupt => _
      connection.close
      exit(0)
    rescue StandardError => e
      logger.error("Consumer Error: #{e.message}")
      retry
    end
  end
end
