require 'bunny'

class EventPublisher
  def self.publish(event_name, payload)
    new.publish(event_name, payload)
  end

  def initialize
    # In production/docker, use ENV, but here fallback to local
    host = ENV.fetch('RABBITMQ_HOST', 'localhost')
    user = ENV.fetch('RABBITMQ_USER', 'guest')
    pass = ENV.fetch('RABBITMQ_PASS', 'guest')

    @connection = Bunny.new(
      hostname: host,
      username: user,
      password: pass
    )
    @connection.start
    @channel = @connection.create_channel

    # Exchange Type: 'direct' or 'topic'. For this test, 'fanout' or 'direct' is simpler.
    @exchange = @channel.fanout(ENV.fetch('RABBITMQ_EXCHANGE', 'shop_system.events'))
  end

  def publish(routing_key, payload)
    # Payload must be JSON serialized
    json_payload = payload.to_json

    @exchange.publish(json_payload, routing_key: routing_key)
    Rails.logger.info("Published event '#{routing_key}' to RabbitMQ: #{json_payload}")

    close_connection
  rescue StandardError => e
    Rails.logger.error("Failed to publish event to RabbitMQ: #{e.message}")
  end

  private

  def close_connection
    @connection.close
  end
end
