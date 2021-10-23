# frozen_string_literal: true

require_relative 'lib/release_feature/version'

Gem::Specification.new do |spec|
  spec.name          = 'release_feature'
  spec.version       = ReleaseFeature::VERSION
  spec.authors       = ['junara']
  spec.email         = ['jung5araki@gmail.com']

  spec.summary       = 'Release feature in custom date range.'
  spec.description   = 'Release feature in custom date range.'
  spec.homepage      = 'https://github.com/junara/release_feature'
  spec.license       = 'MIT'
  spec.required_ruby_version = Gem::Requirement.new('>= 2.7.0')

  spec.metadata['allowed_push_host'] = "TODO: Set to 'http://mygemserver.com'"

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = spec.homepage
  spec.metadata['changelog_uri'] = 'https://github.com/junara/release_feature/blob/main/CHANGELOG.md'

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{\A(?:test|spec|features)/}) }
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']
  spec.add_development_dependency 'activerecord'
  spec.add_development_dependency 'factory_bot'
  spec.add_development_dependency 'rspec'
  spec.add_development_dependency 'rspec-parameterized'
  spec.add_development_dependency 'rubocop'
  spec.add_development_dependency 'rubocop-performance'
  spec.add_development_dependency 'rubocop-rake'
  spec.add_development_dependency 'rubocop-rspec'
  spec.add_development_dependency 'sqlite3'
  spec.add_development_dependency 'timecop'
  spec.add_dependency 'time'
  spec.add_dependency 'tzinfo'
  spec.add_dependency 'yaml'
end
