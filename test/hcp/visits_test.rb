require 'test_helper'

class VisitsTestCase < Minitest::Test
  # Housecall Pro files appointments inside jobs and lists them only where asked, so the visits
  # are read off the jobs booked across the window, expanded, and kept to the window.
  def setup
    @jobs = "#{HousecallStubs::HOST}/jobs"
    @estimates = "#{HousecallStubs::HOST}/estimates"
    @now = Time.now.utc
    stub_request(:get, @estimates).with(query: hash_including(page: '1')).
      to_return body: { total_pages: 1, estimates: [] }.to_json
    stub_request(:get, @jobs).
      with(query: hash_including(page: '1', 'expand' => [ 'appointments' ])).
      to_return body: { total_pages: 1, jobs: [ booked_job, canceled_job ] }.to_json
  end

  def test_reads_every_visit_booked_in_the_window_with_its_job
    visits = account.visits.upcoming(2.weeks).to_a

    assert_equal [ 'appt_1' ], visits.map(&:id)
    assert_equal 'Paint the fence', visits.sole.description
    assert_equal Time.at((@now + 1.day).to_i), visits.sole.starts_at
    assert_equal Time.at((@now + 1.day + 2.hours).to_i), visits.sole.ends_at
    refute visits.sole.anytime?
    assert_equal 'job_1', visits.sole.job.id
    assert_equal '1 Example Street', visits.sole.job.location.street
    assert_equal 'Ada', visits.sole.job.location.customer.name
  end

  def test_reads_every_visit_there_ever_was_where_nothing_narrows_the_list
    visits = account.visits.to_a

    assert_equal %w[appt_1 appt_2], visits.map(&:id)
    assert_requested(:get, @jobs, query: hash_including(page: '1'), times: 1) do |request|
      request.uri.query_values.keys.none? { |key| key.start_with? 'scheduled_' }
    end
  end

  def test_asks_for_the_jobs_booked_across_the_window_with_their_appointments
    account.visits.upcoming(2.weeks).first

    assert_requested(:get, @jobs, query: hash_including(page: '1'), times: 1) do |request|
      min, max = request.uri.query_values.values_at('scheduled_end_min', 'scheduled_start_max')
      (Time.now - Time.iso8601(min)).abs < 60 && (Time.now + 2.weeks - Time.iso8601(max)).abs < 60
    end
  end

private

  def appointment(id, starts_at, anytime: false)
    { id: id, start_time: starts_at.iso8601, end_time: (starts_at + 2.hours).iso8601,
      anytime: anytime, }
  end

  # One stop in the window and one far past it, so the job is booked across it.
  def booked_job
    { id: 'job_1', description: 'Paint the fence', work_status: 'scheduled',
      schedule: { scheduled_start: (@now + 1.day).iso8601,
                  appointments: [ appointment('appt_1', @now + 1.day),
                                  appointment('appt_2', @now + 3.weeks, anytime: true), ], },
      address: { id: 'adr_1', street: '1 Example Street', zip: '90210' },
      customer: { id: 'cus_1', first_name: 'Ada', mobile_number: '(555) 200-0001' },
    }
  end

  def canceled_job
    { id: 'job_2', description: 'Called off', work_status: 'user canceled',
      schedule: { appointments: [ appointment('appt_3', @now + 2.days) ] },
      address: { id: 'adr_2' }, customer: { id: 'cus_2' },
    }
  end
end
