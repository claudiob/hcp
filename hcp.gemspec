require_relative 'lib/hcp/version'

Gem::Specification.new do |spec|
  spec.name = 'hcp'
  spec.version = Hcp::VERSION
  spec.authors = [ 'Claudio Baccigalupo' ]
  spec.email = [ 'claudiob@users.noreply.github.com' ]

  spec.summary = 'A Ruby client for the Housecall Pro API.'
  spec.description = 'Housecall Pro API'
  spec.homepage = 'https://github.com/claudiob/hcp'
  spec.license = 'MIT'
  spec.required_ruby_version = '>= 3.2.0'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['changelog_uri'] = 'https://github.com/claudiob/hcp/blob/main/CHANGELOG.md'
  spec.metadata['documentation_uri'] = 'https://rubydoc.info/gems/hcp'

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ Gemfile Rakefile .gitignore .rubocop.yml test/ .github/])
    end
  end
  spec.bindir = 'exe'
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = [ 'lib' ]

  spec.add_dependency 'activesupport' # blank?, compact_blank and to_query are missing without it
  spec.add_dependency 'company', '~> 4.0' # the account has no vocabulary to answer in without it
  spec.add_dependency 'ice_cube' # an event that repeats has no hours after the first without it
  spec.add_development_dependency 'minitest' # the test suite has no framework to run in without it
  spec.add_development_dependency 'rake' # `rake` has no tasks to run without it
  spec.add_development_dependency 'rubocop-rails-omakase' # `rubocop` has no style to read it by
  spec.add_development_dependency 'simplecov' # a drop below full coverage goes unnoticed without it
  spec.add_development_dependency 'webmock' # the tests reach Housecall Pro for real without it
  spec.add_development_dependency 'yard' # the API reference cannot be built without it
end
