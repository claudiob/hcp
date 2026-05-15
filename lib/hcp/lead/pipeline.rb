module Hcp
  class Lead::Pipeline < Resource
    def initialize(id: nil, key:, company_id:)
      @id = id
      @key = key
      @company_id = company_id
    end

    def update(status_name:)
      status = find_status_by name: status_name
      raise Error, "Status #{status_name} not found for lead #{@id}" unless status

      payload = { resource_type: 'lead', resource_id: @id, status_id: status['id'] }.to_json
      Net::HTTP.put uri, payload, headers
    rescue Errno::ECONNREFUSED => error
      raise Error, error
    end

  private

    def find_status_by(name:)
      body = JSON Net::HTTP.get(uri, headers)
      body['statuses'].find { |status| status['name'] == name } || unknown_status(name: name)
    end

    def unknown_status(name:)
      raise Error, "Status #{name} not found for lead #{@id}"
    end

    def uri = URI 'https://api.housecallpro.com/pipeline/statuses?resource_type=lead'
  end
end
