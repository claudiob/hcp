# The Housecall Pro API Ruby client

The Housecall Pro API, answered in the vocabulary of the [company](https://github.com/claudiob/company)
gem: a key opens an account, the account answers the business it belongs to, its leads and its
jobs, and nothing else. Where a caller reads nothing, this gem has no method.

## How to install

```sh
gem install hcp
```

Or, in a Gemfile, pinned to the current major:

```ruby
gem 'hcp', '~> 2.0'
```

`~> major.minor` means `bundle update` never crosses a breaking change.

## The account

An account is a key, acting as one location where the key opens several:

```ruby
account = Hcp::Account.new key: 'the-api-key'
account = Hcp::Account.new key: 'the-api-key', company_id: 'loc_1'
```

`company_id:` is sent as `X-Company-Id`. The account a key belongs to refuses the header, so it
is only sent where a location is named.

## The business

```ruby
business = account.business
business.id, business.name
business.phone        # => '5555550100', ten digits however Housecall Pro wrote them, or nil
business.subsidiaries # => the business itself first, then every location under it, flat
```

Housecall Pro answers a franchise as a tree several levels deep; `subsidiaries` reads it flat
and is never empty, and each `id` in it is what `company_id:` takes.

## Leads

Opening a lead opens its customer with it, and hands back what Housecall Pro filed both under:

```ruby
lead = account.leads.create name: 'Ada', surname: 'Lovelace', phone: '5550000001',
  email: 'ada@example.com', description: 'Fix the sink', notes: 'Very interested in buying',
  address: { street: '1 Example Street', city: 'Springfield', state: 'CA', zip: '90210' },
  source: 'The Lead Generator'
lead.id, lead.customer.id
```

Moving a lead through the pipeline names the status as the account names it; a name the
account has no status for raises `Hcp::Error`:

```ruby
account.leads.find('lea_1').update status_name: 'Won'
```

## Jobs

The jobs booked to start within a window are walked a page at a time, each read flat and in
dollars however Housecall Pro nested it or counted it:

```ruby
account.jobs.past(4.weeks).each do |job|
  job.id, job.description, job.created_at, job.scheduled_at, job.completed_at
  job.notes             # => "- Gate code 1234\n- Dog in the yard", one to a line
  job.amount            # => 330.0, dollars as a BigDecimal, where Housecall Pro said 33000
  job.quote             # => an Hcp::Quote, the estimate option the job was created from, or nil
  job.quote.amount      # => that option's total in dollars, found among the customer's estimates
  job.location          # => an Hcp::Location, or nil where the job is booked nowhere
  job.location.customer # => an Hcp::Customer: id, name, surname, email, phone
  job.lines             # => Hcp::Line, read off the job's own line_items endpoint on first ask
end
```

A customer's `name` is their first name, or the business's where a person has none, and their
`phone` is the first of the mobile, home and work numbers that can be dialed.

## Visits

A visit is any booked time, and Housecall Pro books it two ways. Work already won is a job,
and Housecall Pro calls its stops appointments and files them inside it. Work still being
looked at is an estimate, which it schedules the same way but hangs no appointments under, so
an estimate holds the one slot. Both are read off the work booked across the window, a page of
it at a time; work called off keeps its stops to itself, and a list nothing narrows walks
every job and estimate there was.

```ruby
account.visits.upcoming(2.weeks).each do |visit|
  visit.id, visit.starts_at, visit.ends_at, visit.anytime?
  visit.description      # => what the job is called, or nil: an estimate has no words of its own
  visit.job              # => the Hcp::Job the stop belongs to, or nil where an estimate does
  visit.lead             # => the Hcp::Estimate it belongs to, or nil where a job does
  visit.technicians      # => the Hcp::Technicians the stop is booked for
end
```

The two cost a list each, so a caller that wants one kind asks for it and spends one request:

```ruby
account.visits.upcoming(2.weeks).for_jobs  # => only the appointments, one request
account.visits.upcoming(2.weeks).for_leads # => only the estimates' slots, one request
```

An estimate reads as the lead it is -- `id`, `customer`, `location` -- because its other half,
the price, is already `Hcp::Quote`: Housecall Pro files the visit and the prices as one record
and the vocabulary reads them as two.

`account.visits.create` is named by the vocabulary and not answered here yet; it raises
`NotImplementedError`. Booking one means `POST /estimates`, which takes a `customer_id` rather
than a customer, so it needs `GET /customers` and `POST /customers` first, and all three want
probing before they are written against.

## The schedule

The crew are Housecall Pro's employees, and the active ones are walked a page at a time:

```ruby
account.technicians.each do |technician|
  technician.id, technician.name, technician.surname
end
```

One technician's week is the visits in it narrowed to them, which is how a schedule reads:

```ruby
monday = Date.today.beginning_of_week.in_time_zone
account.visits.between(monday, monday + 1.week).assigned_to(technician).each do |visit|
  visit.starts_at, visit.ends_at, visit.job.location.street
end
```

Housecall Pro narrows the jobs by who is assigned to them, so the window is asked for as that
technician's and nobody else's jobs come back. It narrows no further: a job's appointments are
dispatched to some of its crew or to none of it, so a stop dispatched to nobody is the whole
crew's, and the stops the technician is not on are let go once the jobs arrive. Asking for the
week and asking for the technician narrow the same list, in either order.

What Housecall Pro schedules elsewhere is still not here: time blocked out on the calendar is
filed under `/events`, which takes no date and no employee to narrow by, so a week of it cannot
be asked for -- only paged in full.

## Errors

Everything descends from `Hcp::Error`, which descends from `Company::Error`, so one rescue
still catches the lot. `Hcp::Throttled`, a `Company::Throttled`, is a refusal for rate, so one
retry covers every platform.

Nothing here sleeps. A caller told to come back later has a queue that can bring the whole job
back, which is worth more than a worker asleep holding a connection open.

## Webhooks

`Hcp::Event` reads a webhook payload, and reaches the network for nothing. The signature and
timestamp headers Housecall Pro signs one with are `Hcp::Event::SIGNATURE_HEADER` and
`Hcp::Event::TIMESTAMP_HEADER`.

```ruby
event = Hcp::Event.new params
event.lead_id, event.customer_id, event.conversion_type, event.conversion_id
event.job_id, event.estimate_id, event.scheduled_at, event.completed_at
event.invoice_id, event.invoice_job_id, event.invoice_amount
```
