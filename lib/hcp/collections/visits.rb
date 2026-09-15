module Hcp
  # The visits of one location: the appointments Housecall Pro files inside jobs, and the slot
  # it files on each estimate. They are read off the work booked across a window, a page of it
  # at a time, and each kind costs a list of its own.
  class Visits < Company::Visits
    # @param client [Client] how to reach Housecall Pro as the location.
    # @param from [Time, nil] the moment the window opens, or nothing for every visit there was.
    # @param to [Time, nil] the moment the window closes, or nothing for every visit to come.
    # @param technician [Company::Technician, nil] whose work to ask for, or nothing for all.
    # @param jobs [Boolean] whether to read the stops of jobs.
    # @param leads [Boolean] whether to read the stops of estimates.
    def initialize(client:, from: nil, to: nil, technician: nil, jobs: true, leads: true)
      @client = client
      @from = from
      @to = to
      @technician = technician
      @jobs = jobs
      @leads = leads
    end

    # @param from [Time, nil] the moment the window opens, or nothing for every visit there was.
    # @param to [Time, nil] the moment the window closes, or nothing for every visit to come.
    # @return [Visits] the same list, narrowed to the visits booked to start between the two.
    def between(from, to) = with from: from, to: to

    # Housecall Pro narrows both lists by who is assigned to the work, so the window is asked
    # for as this technician's; a job's stop is the whole crew's until somebody is dispatched
    # to it, so the stops they are not on are let go once the work comes back.
    # @param technician [Company::Technician] whoever the work is booked for.
    # @return [Company::Selection] the same list, narrowed to the stops they are booked for.
    def assigned_to(technician)
      theirs = with technician: technician
      Company::Selection.new(collection: theirs) do |visit|
        visit.technicians.any? { |each| each.id == technician.id }
      end
    end

    # @return [Visits] the same list, read off the jobs alone: one request rather than two.
    def for_jobs = with leads: false

    # @return [Visits] the same list, read off the estimates alone: one request rather than two.
    def for_leads = with jobs: false

    # Work booked across the window carries every stop in it, so each list is read once and
    # what was called off keeps its stops to itself.
    # @yield [Visit] each visit in the window, the jobs' stops before the estimates'.
    def each(&)
      jobs.each { |job| stops job, & } if @jobs
      estimates.each { |estimate| stops estimate, & } if @leads
    end

  private

    def with(**changed)
      self.class.new(**{ client: @client, from: @from, to: @to, technician: @technician,
                         jobs: @jobs, leads: @leads }.merge(changed))
    end

    def stops(work)
      return if work.canceled?

      work.visits.each { |visit| yield visit if window.cover? visit.starts_at }
    end

    def window = @from..@to

    def crew = { employee_ids: (@technician && [ @technician.id ]) }

    def jobs
      bounds = { scheduled_end_min: @from&.utc&.iso8601, scheduled_start_max: @to&.utc&.iso8601 }
      params = bounds.merge(crew).compact.merge expand: [ 'appointments' ]
      Jobs.new client: @client, params: params
    end

    def estimates
      bounds = { scheduled_start_min: @from&.utc&.iso8601, scheduled_start_max: @to&.utc&.iso8601 }
      Estimates.new client: @client, params: bounds.merge(crew).compact
    end
  end
end
