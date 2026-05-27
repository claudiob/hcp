# frozen_string_literal: true

require_relative 'lib/hcp/version'

Gem::Specification.new do |spec|
  spec.name = 'hcp'
  spec.version = Hcp::VERSION
  spec.authors = ['Claudio Baccigalupo']
  spec.email = ['claudiob@users.noreply.github.com']

  spec.summary = 'A Ruby client for the Housecall Pro API.'
  spec.description = 'Housecall Pro API'
  spec.homepage = 'https://github.com/claudiob/hcp'
  spec.license = 'MIT'
  spec.required_ruby_version = '>= 3.2.0'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = 'https://github.com/claudiob/hcp'
  spec.metadata['changelog_uri'] = 'https://github.com/claudiob/hcp'

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ Gemfile .gitignore .rspec spec/ .github/])
    end
  end
  spec.bindir = 'exe'
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_dependency 'activesupport'
end
