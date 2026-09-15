module Hcp
  # The employees of one location, walked a page at a time. Housecall Pro lists the active
  # ones and no others, so a crew that has left the business is not among them.
  class Technicians < Company::Collection
    # Employees a page: the most Housecall Pro answers with, and more than it refuses.
    PAGE = 200

    # @param client [Client] how to reach Housecall Pro as the location.
    def initialize(client:)
      @client = client
    end

    # Nothing is read until the walk starts, and a page only once the one before it runs out.
    # @yield [Technician] each employee, in the order Housecall Pro lists them.
    def each
      (1..).each do |page|
        body = @client.get 'employees', page: page, page_size: PAGE
        body.fetch('employees').each { |node| yield Technician.new node: node }
        break if page >= body.fetch('total_pages')
      end
    end
  end
end
