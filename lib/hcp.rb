require 'bigdecimal'
require 'json'
require 'net/http'
require 'time'

# Only the Active Support files whose methods are used, rather than the whole of it: a name
# Housecall Pro holds nothing for arrives as readily empty as null, and a query is written the
# way `to_query` writes one.
require 'active_support/core_ext/enumerable'
require 'active_support/core_ext/object/blank'
require 'active_support/core_ext/object/to_query'

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
require 'hcp/resources/job'
require 'hcp/resources/estimate'
require 'hcp/collections/jobs'
require 'hcp/collections/estimates'
require 'hcp/collections/visits'
require 'hcp/collections/technicians'
require 'hcp/account'
require 'hcp/event'
