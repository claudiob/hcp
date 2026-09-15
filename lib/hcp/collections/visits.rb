module Hcp
  # The visits of one location, which Housecall Pro calls appointments and files inside jobs:
  # they are read off the jobs booked across a window, a page of jobs at a time.
  class Visits < Company::Collection
    # @param client [Client] how to reach Housecall Pro as the location.
    # @param from [Time, nil] the moment the window opens, or nothing for every visit there was.
    # @param to [Time, nil] the moment the window closes, or nothing for every visit to come.
    # @param technician [Company::Technician, nil] whose jobs to ask for, or nothing for all.
    def initialize(client:, from: nil, to: nil, technician: nil)
      @client = client
      @from = from
      @to = to
      @technician = technician
    end

    # @param from [Time, nil] the moment the window opens, or nothing for every visit there was.
    # @param to [Time, nil] the moment the window closes, or nothing for every visit to come.
    # @return [Visits] the same list, narrowed to the visits booked to start between the two.
    def between(from, to)
      self.class.new client: @client, from: from, to: to, technician: @technician
    end

    # Housecall Pro narrows the jobs by who is assigned to them, so the window is asked for as
    # this technician's; a stop of one of those jobs is the whole crew's until somebody is
    # dispatched to it, so the stops they are not on are let go once the jobs come back.
    # @param technician [Company::Technician] whoever the work is booked for.
    # @return [Company::Selection] the same list, narrowed to the stops they are booked for.
    def assigned_to(technician)
      theirs = self.class.new client: @client, from: @from, to: @to, technician: technician
      Company::Selection.new collection: theirs, technician: technician
    end

    # A job booked across the window carries every visit in it, so the jobs are read once and
    # a canceled job's visits are left where they are.
    # @yield [Visit] each visit in the window, in the order Housecall Pro lists them.
    def each
      jobs.each do |job|
        next if job.canceled?

        job.visits.each { |visit| yield visit if window.cover? visit.starts_at }
      end
    end

  private

    def window = @from..@to

    def jobs
      bounds = { scheduled_end_min: @from&.utc&.iso8601, scheduled_start_max: @to&.utc&.iso8601,
                 employee_ids: (@technician && [ @technician.id ]) }
      Jobs.new client: @client, params: bounds.compact.merge(expand: [ 'appointments' ])
    end
  end
end
