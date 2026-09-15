module Hcp
  # Work a Housecall Pro user accepted: what it is, who it is for, and what it comes to.
  class Job < Company::Job
    # The node keys Housecall Pro spells otherwise than the vocabulary.
    def self.keys = { amount: :total_amount }

    # Housecall Pro nests when the work is booked and when it was done, and files the address
    # and the customer side by side; the node is read flat, the way the vocabulary reads one.
    # @param node [Hash] job as Housecall Pro answered it.
    # @param client [Client] how to reach Housecall Pro for what the job holds elsewhere.
    def initialize(node: {}, client:)
      node = node.with_indifferent_access
      super node: node.merge(scheduled_at: node.dig(:schedule, :scheduled_start),
        completed_at: node.dig(:work_timestamps, :completed_at), location: location_from(node))
      @client = client
    end

    # Housecall Pro files the notes on a job one by one, which read as a list, one to a line.
    # @return [String, nil] every note's content, `- ` before each, nil where none was written.
    def notes = Array(super).map { |note| "- #{note[:content]}" }.join("\n").presence

    # Housecall Pro counts in cents, and a caller reads dollars.
    # @return [BigDecimal, nil] what the job comes to.
    def amount = (cents = super) && cents / 100

    # Housecall Pro files a job's lines under their own endpoint rather than beside the job,
    # so they are read once, on the first ask.
    # @return [Array<Line>] lines the job is billed as.
    def lines
      @lines ||= @client.get("jobs/#{id}/line_items").fetch('data').map { Line.new node: it }
    end

    # @return [Location, nil] where the work happens, nil where the job is booked nowhere.
    def location = record Location, :location

    # Housecall Pro nests the appointments under the schedule, and only where the list was
    # asked to bring them.
    # @return [Array<Visit>] stops the job is booked as, empty where none came back.
    def visits = Array(@node.dig :schedule, :appointments).map { Visit.new node: it, job: self }

    # @return [Array<Technician>] employees the job is assigned to, empty where it is assigned
    #   to nobody.
    def technicians = records Technician, :assigned_employees

    # @return [Boolean] whether the customer or the pro called the job off.
    def canceled? = attribute(:work_status).to_s.end_with? 'canceled'

    # Housecall Pro names the estimate option a job was created from beside the job, and the
    # option is priced among the customer's estimates, so the quote takes the customer along.
    # @return [Quote, nil] option the job was won with, nil where it was won without one.
    def quote
      option_id = @node[:original_estimate_id]
      Quote.new node: { id: option_id, customer: @node[:customer] }, client: @client if option_id
    end

  private

    def location_from(node)
      node[:address].merge customer: node[:customer] if node.dig(:address, :id).present?
    end
  end
end
