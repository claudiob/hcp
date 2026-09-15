module Hcp
  # The estimates of one location, walked a page at a time. Housecall Pro narrows them by the
  # same words it narrows jobs by, so a window and a crew cost what they cost on a job.
  class Estimates < Company::Collection
    # @param client [Client] how to reach Housecall Pro as the location.
    # @param params [Hash] what the list is narrowed to, as Housecall Pro filters estimates.
    def initialize(client:, params: {})
      @client = client
      @params = params
    end

    # Nothing is read until the walk starts, and a page only once the one before it runs out.
    # @yield [Estimate] each estimate in the window, in the order Housecall Pro lists them.
    def each
      (1..).each do |page|
        body = @client.get 'estimates', @params.merge(page: page, page_size: Jobs::PAGE)
        body.fetch('estimates').each { |node| yield Estimate.new node: node }
        break if page >= body.fetch('total_pages')
      end
    end
  end
end
