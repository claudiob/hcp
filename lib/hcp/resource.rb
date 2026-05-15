module Hcp
  class Resource
    attr_reader :id

  private

    def headers
      {
        'Authorization' => "Token #{@key}",
        'Content-Type' => 'application/json',
        'X-Company-Id' => @company_id,
      }.compact
    end
  end
end
