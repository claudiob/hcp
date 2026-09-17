require 'test_helper'

class OccurrencesTest < Minitest::Test
  # Housecall Pro narrows events by nothing -- it accepts a window and a crew and ignores both
  # -- so the sweep is read in full and kept to the window here.
  def setup
    @events = "#{HousecallStubs::HOST}/events"
    stub_read 'jobs', { total_pages: 1, jobs: [] }, query: hash_including({})
    stub_read 'estimates', { total_pages: 1, estimates: [] }, query: hash_including({})
  end

  def test_reads_an_event_that_happens_once_as_the_one_stretch_it_takes
    stub_events [ once ]

    visits = account.visits.between(monday, monday + 1.week).to_a

    assert_equal [ "evt_1@#{(monday + 2.hours).utc.iso8601}" ], visits.map(&:id)
    assert_equal 'HOLD FOR JOANNE', visits.sole.description
    assert_equal monday + 2.hours, visits.sole.starts_at
    assert_equal monday + 5.hours, visits.sole.ends_at
    refute visits.sole.anytime?
    assert_equal [ 'Grace' ], visits.sole.technicians.map(&:name)
  end

  # Blocked-out time is booked against no work, and Housecall Pro files an address on an event
  # but no ID for it, so it stands nowhere -- as it does in Jobber.
  def test_reads_an_hour_blocked_out_as_standing_on_nothing
    stub_events [ once ]

    visit = account.visits.between(monday, monday + 1.week).sole

    assert_nil visit.job
    assert_nil visit.lead
    assert_nil visit.location
  end

  def test_keeps_an_hour_outside_the_window_out_of_it
    stub_events [ once ]

    assert_empty account.visits.between(monday - 8.weeks, monday - 7.weeks).to_a
  end

  def test_sweeps_every_page_of_events
    stub_request(:get, @events).with(query: hash_including(page: '1')).
      to_return body: { total_pages: 2, events: [ once ] }.to_json
    stub_request(:get, @events).with(query: hash_including(page: '2')).
      to_return body: { total_pages: 2, events: [ also_once ] }.to_json

    assert_equal 2, account.visits.between(monday, monday + 1.week).count
    assert_requested :get, @events, query: hash_including(page: '2'), times: 1
  end

  # The sweep is the expensive half of the list, so a caller after the stops of work alone is
  # spared it: asking for one kind of work is the one way to leave it unasked.
  def test_leaves_the_sweep_unasked_where_only_the_stops_of_work_are_wanted
    account.visits.between(monday, monday + 1.week).for_jobs.to_a
    account.visits.between(monday, monday + 1.week).for_leads.to_a
    account.visits.between(monday, monday + 1.week).for_work.to_a

    assert_not_requested :get, @events
  end

  # Both kinds of stop and neither hour held: the jobs and the estimates are still read, so
  # what is spared is the sweep alone.
  def test_reads_the_work_of_both_kinds_where_the_sweep_is_spared
    stub_events [ once ]

    assert_empty account.visits.between(monday, monday + 1.week).for_work.to_a
    assert_requested :get, "#{HousecallStubs::HOST}/jobs", query: hash_including({}), times: 1
    assert_requested :get, "#{HousecallStubs::HOST}/estimates", query: hash_including({}), times: 1
  end

private

  def monday = Time.iso8601 '2026-09-14T00:00:00Z'

  def stub_events(events)
    stub_read 'events', { total_pages: 1, events: events }, query: hash_including(page: '1')
  end

  def once
    { 'id' => 'evt_1', 'name' => 'HOLD FOR JOANNE', 'all_day' => false,
      'recurrence_rule' => nil,
      'assigned_employees' => [ { 'id' => 'pro_grace', 'first_name' => 'Grace' } ],
      'address' => { 'street' => '', 'city' => '', 'state' => '', 'zip' => '' },
      'schedule' => { 'start_time' => '2026-09-14T02:00:00Z',
                      'end_time' => '2026-09-14T05:00:00Z',
                      'time_zone' => 'America/New_York', }, }
  end

  def also_once = once.merge 'id' => 'evt_4', 'name' => 'Dentist'
end
