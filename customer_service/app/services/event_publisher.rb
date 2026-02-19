require 'bunny'

class EventPublisher
  def self.publish(event_name, payload)
    new.publish(event_name, payload)
  end

  def publish(event_name, payload)
    host = ENV.fetch('RABBITMQ_HOST', 'localhost')
    user = ENV.fetch('RABBITMQ_USER', 'guest')
    pass = ENV.fetch('RABBITMQ_PASS', 'guest')

    connection = Bunny.new(hostname: host, username: user, password: pass)
    connection.start

    channel = connection.create_channel
    exchange = channel.fanout('shop_system.events')

    exchange.publish(payload.to_json, routing_key: event_name)
    
    Rails.logger.info "Published response event '#{event_name}' to RabbitMQ: #{payload.to_json}"
    connection.close
  rescue StandardError => e
    Rails.logger.error "Failed to publish event from Customer Service to RabbitMQ: #{e.message}"
  end
end
