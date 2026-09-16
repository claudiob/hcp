require 'test_helper'

class TechniciansTest < Minitest::Test
  # Housecall Pro assigns a job to a crew and dispatches each of its appointments to some of
  # that crew, or to none of it, so a stop reads its own crew off both.
  def setup
    @jobs = "#{HousecallStubs::HOST}/jobs"
    @now = Time.now.utc
    stub_read 'employees', { total_pages: 1, employees: [ grace, alan ] },
      query: { page: '1', page_size: '200' }
    stub_request(:get, @jobs).with(query: hash_including(page: '1')).
      to_return body: { total_pages: 1, jobs: [ job ] }.to_json
    # Events narrow by nothing, so every read of the visits sweeps them: nobody here blocks
    # out time, and the sweep is the occurrences test's business.
    stub_read 'events', { total_pages: 1, events: [] }, query: hash_including(page: '1')
    stub_request(:get, "#{HousecallStubs::HOST}/estimates").
      with(query: hash_including(page: '1')).
      to_return body: { total_pages: 1, estimates: [] }.to_json
  end

  def test_the_crew_reads_by_the_names_the_vocabulary_gives_it
    technicians = account.technicians.to_a

    assert_equal %w[emp_1 emp_2], technicians.map(&:id)
    assert_equal 'Grace', technicians.first.name
    assert_equal 'Hopper', technicians.first.surname
    assert_requested :get, "#{HousecallStubs::HOST}/employees",
      query: { page: '1', page_size: '200' }
  end

  # A stop dispatched to nobody is the whole crew's, which is how Housecall Pro draws it.
  def test_a_stop_is_booked_for_whoever_was_dispatched_to_it_or_for_the_whole_crew
    dispatched, everyone = account.visits.to_a

    assert_equal %w[emp_1], dispatched.technicians.map(&:id)
    assert_equal %w[emp_1 emp_2], everyone.technicians.map(&:id)
  end

  def test_one_technicians_week_asks_for_their_jobs_and_keeps_the_stops_they_are_on
    alan = account.technicians.find { |technician| technician.id == 'emp_2' }

    assert_equal %w[appt_2], account.visits.upcoming(1.week).assigned_to(alan).ids
    assert_requested :get, @jobs, query: hash_including('employee_ids' => [ 'emp_2' ])
  end

private

  def grace = { id: 'emp_1', first_name: 'Grace', last_name: 'Hopper' }

  def alan = { id: 'emp_2', first_name: 'Alan', last_name: 'Turing' }

  def job
    { id: 'job_1', description: 'Paint the fence', work_status: 'scheduled',
      assigned_employees: [ grace, alan ],
      schedule: { appointments: [ appointment('appt_1', [ 'emp_1' ]),
                                  appointment('appt_2', []), ] },
      address: { id: 'adr_1' }, customer: { id: 'cus_1' }, }
  end

  def appointment(id, dispatched)
    { id: id, start_time: (@now + 1.day).iso8601, end_time: (@now + 1.day + 2.hours).iso8601,
      dispatched_employees_ids: dispatched, }
  end
end
