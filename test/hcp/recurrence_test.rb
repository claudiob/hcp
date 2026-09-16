require 'test_helper'

class RecurrenceTest < Minitest::Test
  # Housecall Pro stores an event that repeats once, as the hour it first takes and the rule it
  # repeats by, so every hour after the first is worked out rather than read.
  def setup
    @events = "#{HousecallStubs::HOST}/events"
    stub_read 'jobs', { total_pages: 1, jobs: [] }, query: hash_including({})
    stub_read 'estimates', { total_pages: 1, estimates: [] }, query: hash_including({})
  end

  def test_works_out_every_hour_a_rule_lands_on_inside_the_window
    stub_events [ weekly ]

    visits = account.visits.between(monday, monday + 4.weeks).to_a

    assert_equal 4, visits.size
    # Each hour answers to the event and the moment it starts, which is what tells them apart
    assert_equal 4, visits.map(&:id).uniq.size
    assert(visits.all? { |visit| visit.id.start_with? 'evt_2@' })
    assert_equal [ 'Busy Fridays' ] * 4, visits.map(&:description)
    # Every hour lasts as long as the one the event was booked for
    assert(visits.all? { |visit| visit.ends_at - visit.starts_at == 1.hour })
  end

  # An event is kept in a time zone rather than in UTC, so an hour that holds at ten in the
  # morning still holds at ten once the clocks have gone back -- an hour later, read as UTC.
  def test_repeats_an_hour_in_the_time_zone_the_event_is_kept_in
    stub_events [ weekly ]

    hours = account.visits.between(october, october + 4.weeks).map { it.starts_at.utc }
    before, after = hours.partition { |hour| hour < Time.iso8601('2026-11-01T06:00:00Z') }

    refute_empty before
    refute_empty after
    assert_equal [ '14:15' ] * before.size, before.map { it.strftime '%H:%M' }
    assert_equal [ '15:15' ] * after.size, after.map { it.strftime '%H:%M' }
  end

  def test_stops_repeating_an_hour_where_the_rule_says_to
    stub_events [ until_october ]

    visits = account.visits.between(monday, monday + 1.year).to_a

    assert_operator visits.size, :<, 52
    assert_operator visits.last.starts_at, :<, Time.iso8601('2026-10-24T04:00:00Z')
  end

private

  def monday = Time.iso8601 '2026-09-14T00:00:00Z'

  def october = Time.iso8601 '2026-10-20T00:00:00Z'

  def stub_events(events)
    stub_read 'events', { total_pages: 1, events: events }, query: hash_including(page: '1')
  end

  def weekly
    { 'id' => 'evt_2', 'name' => 'Busy Fridays', 'all_day' => false,
      'recurrence_rule' => 'FREQ=WEEKLY;BYDAY=FR;WKST=SU',
      'assigned_employees' => [ { 'id' => 'pro_grace', 'first_name' => 'Grace' } ],
      'schedule' => { 'start_time' => '2026-09-18T14:15:00Z',
                      'end_time' => '2026-09-18T15:15:00Z',
                      'time_zone' => 'America/New_York', }, }
  end

  def until_october
    weekly.merge 'id' => 'evt_3',
      'recurrence_rule' => 'FREQ=DAILY;INTERVAL=1;UNTIL=20261024T035959Z;WKST=SU'
  end
end
