module Hcp
  # The Housecall Pro account a key opens, acting as one of its locations.
  class Account < Company::Account
    # @param key [String] API key.
    # @param company_id [String, nil] location to act as, where the account has several.
    def initialize(key:, company_id: nil)
      @client = Client.new key: key, company_id: company_id
    end

    # @return [Business] business the key belongs to, as the location it acts as.
    def business = Business.new node: @client.get('company')

    # @return [Jobs] jobs of the location, walked a page at a time.
    def jobs = Jobs.new client: @client

    # @return [Visits] visits of the location, read off its jobs.
    def visits = Visits.new client: @client

    # @return [Technicians] employees of the location, walked a page at a time.
    def technicians = Technicians.new client: @client

    # @return [Leads] leads of the location, to open and to move.
    def leads = Leads.new client: @client
  end
end
