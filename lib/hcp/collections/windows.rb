module Hcp
  # The free time of one location, which Housecall Pro works out for itself: it holds the hours
  # the business keeps, the notice it needs and the padding it leaves around a job, and answers
  # which stretches of a week are still open. So this asks rather than reckons, and the hours
  # blocked out on the calendar are already taken off.
  class Windows < Company::Windows
    # How far ahead to ask where nothing named an end. Housecall Pro's own default, and a week
    # is what a schedule is read by.
    DAYS = 7

    # @param client [Client] how to reach Housecall Pro as the location.
    # @param technician [Company::Technician, nil] whose free time to ask for, or nothing for
    #   whether anybody at all is free.
    # @param from [Time, nil] the moment the window opens, or nothing for the first day open.
    # @param to [Time, nil] the moment the window closes, or nothing for a week of it.
    def initialize(client:, technician: nil, from: nil, to: nil)
      @client = client
      @technician = technician
      @from = from
      @to = to
    end

    # @param from [Time, nil] the moment the window opens, or nothing for the first day open.
    # @param to [Time, nil] the moment the window closes, or nothing for a week of it.
    # @return [Windows] the same list, narrowed to the free time between the two.
    def between(from, to) = with(from: from, to: to)

    # Housecall Pro narrows free time by who it is free for, so the technician joins the window
    # in the one request and nobody else's hours are answered or paid for.
    # @param technician [Company::Technician] whose free time to answer.
    # @return [Windows] the same list, as that technician's alone.
    def of(technician) = with(technician: technician)

    # Housecall Pro answers a week as a row of short windows, each open or not. Consecutive open
    # ones are one stretch of free time and are joined back into it, so what comes out is as long
    # as the pro is actually free rather than as long as their booking page happens to offer.
    # @yield [Company::Window] each stretch nobody is booked for, earliest first.
    def each
      joined(open).each do |from, to|
        yield Company::Window.new node: { starts_at: from, ends_at: to }
      end
    end

  private

    def open = answered.select { it['available'] }.map { [ it['start_time'], it['end_time'] ] }

    def joined(windows)
      windows.each_with_object [] do |(from, to), stretches|
        carries_on = stretches.last && stretches.last[1] == from
        carries_on ? stretches.last[1] = to : stretches << [ from, to ]
      end
    end

    # An account with nothing open answers a bare list rather than the usual object, so the
    # windows are taken out of whichever shape came back.
    def answered
      body = @client.get 'company/schedule_availability/booking_windows', params
      body.is_a?(Array) ? body : body.fetch('booking_windows', [])
    end

    def params
      { start_date: @from&.utc&.strftime('%Y-%m-%dT%H:%M:%S'), show_for_days: days,
        employee_ids: (@technician && [ @technician.id ]), }.compact
    end

    def days = (@to && @from) ? ((@to - @from) / 1.day).ceil : DAYS

    def with(**changed)
      self.class.new(**{ client: @client, technician: @technician, from: @from,
                         to: @to, }.merge(changed))
    end
  end
end
