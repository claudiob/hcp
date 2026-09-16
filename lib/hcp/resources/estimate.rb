module Hcp
  # Work a Housecall Pro user was asked to look at and price, which the vocabulary reads as the
  # lead it is: a stop to go and see it, before there is a job. Housecall Pro schedules it the
  # way it schedules a job but hangs no appointments under it, so it holds the one slot.
  class Estimate < Company::Lead
    # @return [Customer, nil] customer the estimate was opened for.
    def customer = record Customer, :customer

    # Housecall Pro files the address and the customer side by side, the way it does on a job.
    # @return [Location, nil] where the work would happen, nil where it is booked nowhere.
    def location
      address = @node[:address]
      Location.new node: address.merge(customer: @node[:customer]) if address[:id].present?
    end

    # @return [Array<Technician>] employees the estimate is assigned to.
    def technicians = records Technician, :assigned_employees

    # Housecall Pro gives an estimate no words of its own: what it says is said by its options.
    # @return [nil] nothing, so a stop of one goes undescribed.
    def description = nil

    # Housecall Pro files no ID on the slot, there being only ever the one, so it answers to the
    # estimate's own, and books it for an hour rather than for any time in a day.
    # @return [Array<Visit>] the one slot the estimate is booked for, empty where it has none.
    def visits
      booked = @node.dig :schedule, :scheduled_start
      return [] if booked.blank?

      [ Visit.new(node: slot, lead: self) ]
    end

    # @return [Boolean] whether the customer or the pro called the estimate off.
    def canceled? = attribute(:work_status).to_s.end_with? 'canceled'

  private

    def slot
      { id: id, anytime: false, start_time: @node.dig(:schedule, :scheduled_start),
        end_time: @node.dig(:schedule, :scheduled_end) }
    end
  end
end
