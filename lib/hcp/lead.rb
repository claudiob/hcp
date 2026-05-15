module Hcp
  class Lead < Resource
    attr_reader :customer_id

    def initialize(id: nil, customer_id: nil, key:, company_id:)
      @id = id
      @key = key
      @company_id = company_id
      @customer_id = customer_id
    end

    def create(params = {})
      body = JSON Net::HTTP.post(uri, lead_for(params).to_json, headers).body
      @id, @customer_id = body['id'], body.dig('customer', 'id')
    rescue Errno::ECONNREFUSED => error
      raise Error, error
    end

    def lead_for(params = {})
      {
        customer: customer_for(params), address: params[:address],
        lead_source: params[:source], note: params[:note]
      }.compact_blank
    end

    def customer_for(params = {})
      {
        first_name: params[:name], email: params[:email],
        mobile_number: params[:phone], lead_source: params[:source],
      }.compact_blank
    end

    def uri = URI 'https://api.housecallpro.com/leads'
  end
end
