## [Unreleased]

## [3.1.0] - 2026-09-16

- [Feature] `account.visits` covers the time blocked out around the work, which Housecall Pro
  files as events: a hold, a day off, an hour that is simply not free. It occupies a pro
  exactly as a stop does, and Jobber has answered with it all along, so a schedule read through
  this gem now says the same thing as one read through `jbr`. Each reads as a `Hcp::Occurrence`
  standing on no job and no lead, and a caller that wants what it had before asks `for_jobs`.

- [Feature] An event that repeats is stored by Housecall Pro once, as the hour it first takes
  and the iCalendar rule it repeats by, so the hours after that are worked out here -- in the
  time zone the event is kept in, so an hour that holds at ten in the morning still holds at
  ten once the clocks have gone back rather than sliding to nine. `ice_cube` walks the rule;
  it is a new runtime dependency, and the reason not to hand-roll one is that rule, DST and
  month-end clamping together are where a hand-rolled walk quietly goes wrong.

- [Feature] An hour answers to the event's ID and the moment it starts -- `evt_1@2026-09-18T14:15:00Z`
  -- there being one ID for the whole rule and nothing else to tell two of its hours apart.

- [Note] Housecall Pro narrows events by nothing. `/events` accepts `scheduled_start_min`,
  `scheduled_start_max` and `employee_ids[]` and ignores all three, answering with the same
  total every time, so a week is read by sweeping every page at 200 a page and keeping what the
  week holds. On an account with 2,877 events that is 15 requests, which a nightly walk can
  afford and a caller that only wants the stops of work should not pay: `for_jobs` and
  `for_leads` now leave the sweep unasked.

- [Note] An event carries an address but no ID for it, and leaves it empty on all but a
  handful, so `visit.location` is nil on blocked-out time -- as it is in Jobber, where an event
  carries no property either.

## [3.0.1] - 2026-09-15

- [Fix] `visit.anytime?` answers false on an estimate's slot rather than nil. Housecall Pro
  books an estimate for an hour and has no anytime to answer with, so the slot named none --
  and a caller storing what a visit reads had a nil where it expected a yes or a no.

## [3.0.0] - 2026-09-15

- [Breaking change] The vocabulary is `company` 2.1: a `Company::Selection` takes its rule as a
  block, a visit answers a lead as well as a job, and it says where it is. The pin is `~> 2.1`.

- [Breaking change] `account.visits` is every stop booked, not only a job's: an estimate is
  work still being looked at, so its slot is a visit too, and the list now reads `/jobs` and
  `/estimates` rather than `/jobs` alone. `visit.job` is nil on an estimate's slot and
  `visit.lead` is the `Hcp::Estimate`; `visit.description` is nil there, Housecall Pro giving
  an estimate no words of its own. A caller that wants what it had before asks
  `account.visits.for_jobs`, which is the one request it always was, and `for_leads` is the
  estimates alone.

- [Feature] `Hcp::Estimate`, a `Company::Lead`: `id`, `customer`, `location`, `technicians` and
  the one slot it is booked for. Housecall Pro expands an estimate with `attachments` and not
  with appointments, so the estimate's own `schedule` is the slot and answers to its ID.

- [Feature] `Hcp::Visit#location`, where the stop is: an appointment has no address of its own
  and takes the job's, an estimate's slot takes the estimate's. Both nodes are read in full
  already, so it costs nothing and is always there.

- [Feature] `Hcp::Visit#lead`, and `technicians` reading an estimate's `assigned_employees`
  where a job's stop reads its dispatch.

- [Feature] `account.technicians` walks the location's employees a page at a time, each an
  `Hcp::Technician` reading `id`, `name` off `first_name` and `surname` off `last_name`.

- [Feature] `job.technicians` is the crew a job is assigned to, and `visit.technicians` whoever
  an appointment was dispatched to -- or, where it was dispatched to nobody, the job's whole
  crew, which is how Housecall Pro draws it.

- [Feature] `account.visits.between(from, to).assigned_to(technician)` is one technician's
  week. The window goes to Housecall Pro as `employee_ids`, so only their jobs come back, and
  the stops of those jobs they are not on are let go as the jobs arrive.

## [2.0.0] - 2026-09-09

- [Breaking change] The key is one account's: `Hcp::Account.new(key:, company_id:)`, a
  `Company::Account`, answers `business` and `leads`. `Hcp.key`, `Hcp.with_key`, `Hcp::Access`
  and `HCP_KEY` go.

- [Breaking change] `Hcp::Company` is `Hcp::Business`, a `Company::Business`: `id`, `name`,
  `phone` as ten digits and `subsidiaries`, which was `locations` and which the vocabulary
  now lists off the locations Housecall Pro nests. `website`, `time_zone`,
  `logo_url`, `support_email`, `arrival_window`, `address` and `zip_codes` go.

- [Breaking change] `Hcp::Lead.new(key:, company_id:).create` is `account.leads.create`, which
  takes the vocabulary's words -- `name:`, `surname:`, `phone:`, `email:`, `address:`,
  `description:`, `notes:`, `source:`, the description heading the note -- and answers the lead; `Hcp::Lead::Pipeline` is
  `account.leads.find(id).update(status_name:)`. Writes go through the same plumbing as reads,
  so a refusal is read the three ways Housecall Pro writes one.

- [Breaking change] Gone, unread by any caller: `Relation`, `Chainable`, `Queryable`, `Filter`,
  `Job`, `Job::Appointment`, `Job::Invoice`, `Estimate`, `Estimate::Option`, `Customer`,
  `Employee`, `Schedule`, `Note`, `LineItem`, `Address`, `BookingWindow`, `Hcp::NotFound` --
  a 404 raises `Hcp::Error` -- `Hcp::TooManyRequests#reset_at` and `Hcp::Event#type`.

- [Breaking change] `Hcp::TooManyRequests` is `Hcp::Throttled`, a `Company::Throttled` rather
  than an `Hcp::Error`, so one rescue retries a refusal for rate from any platform.

- [Feature] `account.jobs.past(within)` walks the jobs booked to start in the window a page at a
  time, each an `Hcp::Job` reading in the vocabulary: `scheduled_at` and `completed_at` off the
  nested schedule and timestamps, `notes` listed one to a line,
  `amount` in dollars off the cents, `quote` the estimate option
  the job was created from -- its `amount` the option's total, found once among the customer's
  estimates --
  `location` with its `customer` beside it, and `lines` read once off the job's own endpoint.

- [Feature] `account.visits.upcoming(within)` walks the visits booked to start in the window,
  which Housecall Pro calls appointments and files inside jobs: the jobs booked across the
  window are read with their appointments, a canceled job's are skipped, and each `Hcp::Visit`
  answers `starts_at`, `ends_at`, `anytime?`, its job's `description` and the `job` itself.

- [Feature] `Hcp::Error` descends from `Company::Error`, so one rescue covers every platform.

## [1.4.0] - 2026-08-28

- [Feature] Read as a key for one block, on one thread: `Hcp.with_key(key, company_id:)`,
  which hands the block an `Hcp::Access` answering `account`. A process serving several
  accounts held them all on one `Hcp.key`, so two threads could read each other's; a key
  handed to a block is the thread's alone, and the one set before it comes back after.

- [Feature] Read the account a key belongs to: `Hcp::Company.current`, taking `company_id:`.
  There is no list of companies and no ID to find one by, so it is `current` rather than
  `find` or `where`. `locations` is the account itself and then every location under it at
  any depth, flat, so it is never empty; each ID is what `company_id:` takes everywhere else.

- [Fix] `Hcp::Address#latitude` and `#longitude` answer a `Float` whichever endpoint they were
  read from. Housecall Pro stamps them as numbers under a customer and as strings under the
  company, and the gem documented `Float` while handing back whatever arrived.

- [Feature] Read when the account is free to be booked into: `Hcp::BookingWindow.all`, taking
  `starts_at:`, `days:`, `minutes:`, `service_id:`, `price_form_id:` and `employee_ids:`.
  Housecall Pro answers this list whole rather than a page at a time, so it comes back as an
  `Array` rather than as a relation.

## [1.3.0] - 2026-08-25

- [Feature] Read customers, estimates, jobs and job appointments as an Active Record relation:
  `Hcp::Job.all`, `.where`, `.order`, `.limit`, `.includes`, `.find`, `.count` and `.first`,
  walked lazily a page at a time.
- [Feature] Set the API key once, with `Hcp.key` or `HCP_KEY`, and pass `company_id:` per call.
- [Feature] Narrow a list by a range — `where(scheduled_at: ..2.days.ago)` — and refuse a
  condition, an order or an expansion Housecall Pro does not take, which it answers by
  ignoring rather than by refusing.
- [Feature] Raise `Hcp::NotFound` where Housecall Pro has no such record, and
  `Hcp::TooManyRequests`, carrying `reset_at`, where it refuses one for rate. Both descend
  from `Hcp::Error`, so an existing rescue still catches them.
- [Fix] `require 'hcp'` defines `Hcp::VERSION`, which until now was only set as a side effect
  of Bundler evaluating the gemspec.
- [Breaking change] `Hcp::Lead#lead_for`, `#customer_for` and `#uri` are now private, and
  neither `Hcp::Lead` nor `Hcp::Lead::Pipeline` inherits from `Hcp::Resource`, which is now a
  record rather than a holder of credentials. Nothing documented ever called them.

## [1.2.4] - 2026-06-17

- [Fix] Set event.type when params is nil

## [1.2.3] - 2026-06-15

- [New] Parse estimate_id for :estimate_sent event

## [1.2.2] - 2026-06-15

- [Fix] Replace Net::HTTPOK with broader Net::HTTPSuccess

## [1.2.1] - 2026-06-10

- [Fix] Raise if Lead.create is not successful

## [1.2.0] - 2026-06-08

- [Fix] Raise if Lead::Pipeline.update is not successful

## [1.1.1] - 2026-05-28

- [Fix] Don't include query params in PUT /pipeline/statuses

## [1.1.0] - 2026-05-27

- [New] Add Hcp::Event

## [1.0.0] - 2026-05-15

- Initial release: Lead and Lead::Pipeline classes
