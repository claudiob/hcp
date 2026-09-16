require 'test_helper'

class WindowsTest < Minitest::Test
  # Housecall Pro works free time out for itself -- the hours kept, the notice needed, the
  # padding round a job, the calendar blocked out -- and answers a week as short windows, each
  # open or not. Consecutive open ones are one stretch and are joined back into it.
  def setup
    @windows = "#{HousecallStubs::HOST}/company/schedule_availability/booking_windows"
  end

  def test_joins_the_open_windows_back_into_the_stretches_they_came_from
    stub_windows [ open('09:00', '09:30'), open('09:30', '10:00'), shut('10:00', '10:30'),
                   open('10:30', '11:30'), ]

    free = account.windows.to_a

    assert_equal 2, free.size
    assert_equal Time.iso8601('2026-09-18T09:00:00Z'), free.first.starts_at
    assert_equal Time.iso8601('2026-09-18T10:00:00Z'), free.first.ends_at
    assert_equal 1.hour, free.last.ends_at - free.last.starts_at
    assert_equal %i[starts_at ends_at], Company::Window.node_keys
  end

  def test_asks_for_a_week_from_now_where_nothing_named_an_end
    stub_windows []

    account.windows.to_a

    assert_requested :get, @windows, query: hash_including({}), times: 1 do |request|
      request.uri.query_values == { 'show_for_days' => '7' }
    end
  end

  def test_asks_for_the_days_the_window_covers_and_the_pro_it_is_for
    stub_windows []
    monday = Time.iso8601 '2026-09-14T00:00:00Z'

    account.windows.between(monday, monday + 3.days).of(technician).to_a

    assert_requested :get, @windows, query: hash_including({}), times: 1 do |request|
      request.uri.query_values == { 'start_date' => '2026-09-14T00:00:00', 'show_for_days' => '3',
                                    'employee_ids[]' => 'emp_1', }
    end
  end

  # An account with nothing open answers a bare list rather than the usual object.
  def test_reads_a_week_with_nothing_open_whichever_shape_it_comes_back_in
    stub_request(:get, @windows).with(query: hash_including({})).to_return body: [].to_json

    assert_empty account.windows.to_a
  end

private

  def technician = Company::Technician.new node: { id: 'emp_1', name: 'Grace' }

  def open(from, to) = window(from, to).merge 'available' => true

  def shut(from, to) = window(from, to).merge 'available' => false

  def window(from, to)
    { 'start_time' => "2026-09-18T#{from}:00Z", 'end_time' => "2026-09-18T#{to}:00Z" }
  end

  def stub_windows(booking_windows)
    stub_request(:get, @windows).with(query: hash_including({})).
      to_return body: { booking_windows: booking_windows, show_for_days: 7 }.to_json
  end
end
