require 'bigdecimal'
require 'json'
require 'net/http'
require 'time'

# Only the Active Support files whose methods are used, rather than the whole of it: a name
# Housecall Pro holds nothing for arrives as readily empty as null, and a query is written the
# way `to_query` writes one.
require 'active_support/core_ext/enumerable'
require 'active_support/core_ext/integer/time'
require 'active_support/core_ext/numeric/time'
require 'active_support/core_ext/object/blank'
require 'active_support/core_ext/object/to_query'
require 'active_support/core_ext/time/zones'

# An event repeats by an iCalendar rule, which is walked rather than parsed here: an hour that
# holds at ten in the morning either side of the clocks going back is not worth rewriting.
require 'ice_cube'

# The vocabulary the account answers in.
require 'company'

require 'hcp/version'
require 'hcp/error'
require 'hcp/errors/throttled'

# Answer before Client, which reads one, and Client before everything that talks through it.
require 'hcp/answer'
require 'hcp/client'
require 'hcp/resources/business'
require 'hcp/resources/lead'
require 'hcp/collections/leads'

# Every record before the one that reads it beside itself, and the job before its list.
require 'hcp/resources/customer'
require 'hcp/resources/technician'
require 'hcp/resources/location'
require 'hcp/resources/line'
require 'hcp/resources/quote'
require 'hcp/resources/visit'
require 'hcp/resources/occurrence'
require 'hcp/resources/job'
require 'hcp/resources/estimate'
require 'hcp/collections/jobs'
require 'hcp/collections/estimates'
require 'hcp/collections/occurrences'
require 'hcp/collections/visits'
require 'hcp/collections/technicians'
require 'hcp/account'
require 'hcp/event'
