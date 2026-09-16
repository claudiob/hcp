module Hcp
  # One stretch of blocked-out time: what a Housecall Pro event takes, once where the event
  # happens once and once for every hour its rule lands on where it repeats. Housecall Pro files
  # one ID for the whole rule rather than one per hour, so an hour answers to the event's ID and
  # the moment it starts, which is the one thing telling two hours of the same event apart.
  class Occurrence < Company::Visit
    # The node keys Housecall Pro spells otherwise than the vocabulary.
    def self.keys
      { description: :name, anytime: :all_day, starts_at: :start_time, ends_at: :end_time }
    end

    # Housecall Pro files an address on an event but no ID for it, and leaves it empty on all
    # but a handful, so there is nothing to file a place under: blocked-out time stands nowhere,
    # as it does in Jobber, where an event carries no property either.
    # @return [nil] nothing, so an hour blocked out is booked at no address.
    def location = nil

    # @return [Array<Technician>] whoever the hour is blocked out for.
    def technicians = records Technician, :assigned_employees
  end
end
