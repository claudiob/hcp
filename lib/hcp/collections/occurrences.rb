module Hcp
  # The blocked-out time of one location: the hours Housecall Pro files as events rather than as
  # work. It narrows events by nothing -- neither a window nor a crew, both of which it accepts
  # and ignores -- so the only way to read a week of them is to sweep every page and keep what
  # the week holds. An event that repeats is stored once, as the hour it first takes and the
  # iCalendar rule it repeats by, so every hour after that is worked out here rather than read.
  class Occurrences < Company::Collection
    # How far an open end reaches. A rule that repeats forever has no last hour to walk to, so a
    # caller who named no end gets a year of them, which is a schedule rather than an eternity.
    HORIZON = 1.year

    # @param client [Client] how to reach Housecall Pro as the location.
    # @param from [Time, nil] the moment the window opens, or nothing for from now on.
    # @param to [Time, nil] the moment the window closes, or nothing for a year of it.
    def initialize(client:, from: nil, to: nil)
      @client = client
      @from = from
      @to = to
    end

    # @param from [Time, nil] the moment the window opens, or nothing for from now on.
    # @param to [Time, nil] the moment the window closes, or nothing for a year of it.
    # @return [Occurrences] the same list, narrowed to the hours taken between the two.
    def between(from, to) = self.class.new(client: @client, from: from, to: to)

    # Nothing is read until the walk starts, and a page only once the one before it runs out.
    # @yield [Occurrence] each stretch blocked out in the window, event by event.
    def each
      events { |event| hours_of(event).each { |node| yield Occurrence.new node: node } }
    end

  private

    def events
      (1..).each do |page|
        body = @client.get 'events', page: page, page_size: Jobs::PAGE
        body.fetch('events').each { |node| yield node }
        break if page >= body.fetch('total_pages')
      end
    end

    def hours_of(event)
      schedule = event.fetch 'schedule'
      first = Time.iso8601 schedule.fetch('start_time')
      length = Time.iso8601(schedule.fetch('end_time')) - first
      starts(event['recurrence_rule'], first, schedule['time_zone']).map do |moment|
        event.merge 'id' => "#{event['id']}@#{moment.utc.iso8601}",
          'start_time' => moment.utc.iso8601, 'end_time' => (moment + length).utc.iso8601
      end
    end

    # An hour is repeated in the time zone the event is kept in rather than in UTC, so a rule
    # that says ten in the morning still says ten once the clocks have gone back.
    def starts(rule, first, zone)
      return [ first ].select { |moment| window.cover? moment } if rule.blank?

      repeated rule, first.in_time_zone(zone || 'UTC')
    end

    def repeated(rule, first)
      schedule = IceCube::Schedule.new first
      schedule.add_recurrence_rule IceCube::Rule.from_ical(rule)
      schedule.occurrences_between opens, closes
    end

    def window = opens..closes

    def opens = @from || Time.now

    def closes = @to || opens + HORIZON
  end
end
