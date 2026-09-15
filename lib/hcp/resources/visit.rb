module Hcp
  # One stop, which Housecall Pro hangs under a job as an appointment and under an estimate as
  # the estimate's own slot: it happens where the work does and says what the work says.
  class Visit < Company::Visit
    # The node keys Housecall Pro spells otherwise than the vocabulary.
    def self.keys = { starts_at: :start_time, ends_at: :end_time }

    # @param node [Hash] slot as Housecall Pro answered it under the work it belongs to.
    # @param job [Job, nil] job the slot sits under, nil where an estimate does.
    # @param lead [Estimate, nil] estimate the slot sits under, nil where a job does.
    def initialize(node: {}, job: nil, lead: nil)
      super node: node
      @job = job
      @lead = lead
    end

    # @return [Job, nil] job the stop belongs to, nil where the stop is an estimate's.
    attr_reader :job

    # @return [Estimate, nil] estimate the stop belongs to, nil where the stop is a job's.
    attr_reader :lead

    # @return [String, nil] what the work is called: a stop has no words of its own.
    def description = work.description

    # An appointment has no address of its own and an estimate's slot is the estimate's, so a
    # stop is where its work is.
    # @return [Location, nil] where the stop happens, nil where the work is booked nowhere.
    def location = work.location

    # Housecall Pro dispatches a job's stop to some of its crew, or to none of it, and a stop
    # dispatched to nobody is the whole crew's. An estimate dispatches nothing and has one crew.
    # @return [Array<Technician>] whoever the stop is booked for.
    def technicians = dispatched.presence || work.technicians

  private

    def work = @job || @lead

    def dispatched
      ids = Array attribute(:dispatched_employees_ids)
      work.technicians.select { |technician| ids.include? technician.id }
    end
  end
end
