require 'httparty'

class CustomerServiceClient
  include HTTParty
  base_uri ENV.fetch('CUSTOMER_SERVICE_URL', 'http://localhost:3000')

  def initialize
    # HTTParty handles base_uri via class method or instance
  end

  def find_customer(customer_id)
    response = self.class.get("/customers/#{customer_id}")

    if response.success?
      response.parsed_response
    elsif response.code == 404
      nil
    else
      Rails.logger.error("Error communicating with Customer Service: #{response.code} #{response.body}")
      raise ServiceUnavailableError, "Customer Service unavailable"
    end
  rescue Errno::ECONNREFUSED => e
    Rails.logger.error("Customer Service Connection Refused: #{e.message}")
    raise ServiceUnavailableError, "Customer Service is unreachable"
  end

  class ServiceUnavailableError < StandardError; end
end
