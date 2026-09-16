require 'test_helper'

# Housecall Pro schedules an estimate the way it schedules a job but hangs no appointments
# under it, so the estimate holds the one slot, and that slot is a stop of a lead.
class EstimateVisitsTest < Minitest::Test
  def setup
    @jobs = "#{HousecallStubs::HOST}/jobs"
    @estimates = "#{HousecallStubs::HOST}/estimates"
    @now = Time.now.utc
    stub_read 'jobs', { total_pages: 1, jobs: [ job ] }, query: hash_including(page: '1')
    stub_read 'estimates', { total_pages: 1, estimates: [ estimate, called_off, unscheduled ] },
      query: hash_including(page: '1')
  end

  def test_an_estimates_slot_is_a_stop_of_a_lead_and_says_where_to_go
    visit = account.visits.upcoming(2.weeks).for_leads.first

    assert_equal 'est_1', visit.lead.id
    assert_nil visit.job
    assert_nil visit.description
    assert_equal Time.at((@now + 1.day).to_i), visit.starts_at
    refute visit.anytime?
    assert_equal %w[emp_1], visit.technicians.map(&:id)
    assert_equal '9 Example Street', visit.location.street
    assert_equal '9 Example Street', visit.lead.location.street
    assert_equal 'Ada', visit.lead.customer.name
  end

  # An estimate nobody booked occupies nothing, and one called off keeps its slot to itself.
  def test_only_the_estimates_that_are_booked_and_still_on_occupy_the_day
    assert_equal %w[est_1], account.visits.for_leads.map { |visit| visit.lead.id }
  end

  # The two kinds cost a list each, so asking for one kind spends one request, not two.
  def test_asking_for_one_kind_of_stop_reads_one_list
    assert_equal %w[appt_1], account.visits.for_jobs.ids
    assert_requested :get, @jobs, query: hash_including(page: '1'), times: 1
    assert_not_requested :get, @estimates
  end

  def test_the_whole_schedule_is_both_kinds_the_jobs_stops_first
    assert_equal %w[appt_1 est_1], account.visits.upcoming(2.weeks).ids
    assert_requested :get, @jobs, query: hash_including(page: '1'), times: 1
    assert_requested :get, @estimates, query: hash_including(page: '1'), times: 1
  end

  # Housecall Pro narrows both lists by who the work is assigned to.
  def test_one_technicians_week_asks_both_lists_for_their_work
    grace = Hcp::Technician.new node: { id: 'emp_1' }

    assert_equal %w[appt_1 est_1], account.visits.upcoming(2.weeks).assigned_to(grace).ids
    [ @jobs, @estimates ].each do |list|
      assert_requested :get, list, query: hash_including('employee_ids' => [ 'emp_1' ])
    end
  end

  # Booking one is not written yet: the vocabulary names it and this gem does not answer it.
  def test_booking_a_stop_is_not_answered_yet
    error = assert_raises NotImplementedError do
      account.visits.create name: 'Ada', surname: nil, phone: '5552000001', email: nil,
        address: nil, description: 'Look at the roof', notes: nil, source: nil,
        starts_at: @now, ends_at: nil, technicians: []
    end

    assert_equal 'Hcp::Visits does not book a visit', error.message
  end

private

  def crew = [ { id: 'emp_1', first_name: 'Grace', last_name: 'Hopper' } ]

  def job
    { id: 'job_1', description: 'Paint the fence', work_status: 'scheduled',
      assigned_employees: crew,
      schedule: { appointments: [ { id: 'appt_1', start_time: (@now + 2.days).iso8601,
                                    end_time: (@now + 2.days + 1.hour).iso8601 } ] },
      address: { id: 'adr_1' }, customer: { id: 'cus_1' }, }
  end

  def estimate(id: 'est_1', status: 'scheduled', booked: true)
    schedule = { scheduled_start: (@now + 1.day).iso8601,
                 scheduled_end: (@now + 1.day + 1.hour).iso8601, }
    { id: id, work_status: status, schedule: (booked ? schedule : {}),
      assigned_employees: crew, address: { id: 'adr_9', street: '9 Example Street' },
      customer: { id: 'cus_9', first_name: 'Ada', mobile_number: '(555) 200-0001' }, }
  end

  def called_off = estimate(id: 'est_2', status: 'pro canceled')

  def unscheduled = estimate(id: 'est_3', booked: false)
end
