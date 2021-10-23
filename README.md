# ReleaseFeature

ReleaseFeature is feature toggle.

## Installation

```ruby
gem 'release_feature', git: 'git://github.com/junara/junara_export_csv.git', branch: 'main'
```

And then execute:

    $ bundle install

## Usage

Prepare client by configuring repository and initialize client.

You can select repository from yaml (YamlRepository), hash (HashRepository) or ActiveRecord (ActiveRecordRepository).

Client can have maximum 2 repositories (called to base_repository and extra_repository). extra_repository is optional.

If extra_repository is set, base_repository is merged by extra_repository. extra_repository setting has priority

### Using hash repository

```ruby
config = { features: { hogehoge_function: { development: { open_at: Time.now, close_at: Time.now + 60 * 60 * 24 * 30 } } } }
hash_repo = ReleaseFeature::Repository::HashRepository.new(hash: config)
client = ReleaseFeature::Client.new(environment: :development, base_repository: hash_repo)
client.permitted?(:hogehoge_function) #=> true
client.permitted?(:hogehoge_function, time: Time.now + 60) #=> true
client.permitted?(:hogehoge_function, time: Time.now - 60 * 60 * 24) #=> false

```

### Using yaml repository

Create yaml in 'release_feature_config.yml'. Write following.

```yaml
timezone: Asia/Tokyo
features:
  hoge_feature:
    development:
      open_at: 2000-01-01 00:00
      close_at: 2999-12-31 23:59
    staging:
      open_at: 2030-11-01 10:00
      close_at: 2999-12-31 23:59
    production:
      open_at: 2040-12-01 10:00
      close_at: 2999-12-31 23:59
  puyo_feature:
    development:
      open_at: 2000-01-01 00:00
      close_at: 2999-12-31 23:59
    production:
      open_at: 2022-12-01 10:00
      close_at: 2999-12-31 23:59
```

Set `timezone` from all_identifiers. See [TZInfo](https://github.com/tzinfo/tzinfo#data-sources)

```ruby
require 'tzinfo'
TZInfo::Timezone.all_identifiers
# => ["Africa/Adibdjan", "Africa/Accra", ..., "Zulu"]

```

```ruby
path = 'release_feature_config.yml'
yaml_repo = ReleaseFeature::Repository::YamlRepository.new(path: path)
development_client = ReleaseFeature::Client.new(environment: :development, base_repository: yaml_repo)
development_client.permitted?(:hoge_feature) #=> true

development_client = ReleaseFeature::Client.new(environment: :staging, base_repository: yaml_repo)
development_client.permitted?(:hoge_feature) #=> false

```

### Using ActiveRecord repository

Under Construction

```ruby
model = HogeModel # migrated by active_record
# HogeModel have four attributes (name (:string), environment (:string), open_at (:datetime), close_at (:datetime) 
# HogeModel have 1 record. (name="hoge_feature", environment: "development", open_at: '2000-01-01 00:00 +09:00', close_at: '2000-01-01 00:00 +09:00')
ar_repo = ReleaseFeature::Repository::ActiveRecordRepository.new(model: model)
client = ReleaseFeature::Client.new(environment: :development, base_repository: ar_repo)
client.permitted?(:hoge_feature) #=> true

```

### Using extra_repository repository

Under Construction extra_repository overrides base_repository.

```ruby

path = 'release_feature_config.yml'
yaml_repo = ReleaseFeature::Repository::YamlRepository.new(path: path)

model = HogeModel # migrated by active_record
# HogeModel have four attributes (name (:string), environment (:string), open_at (:datetime), close_at (:datetime) 
# HogeModel have 1 record. (name="hoge_feature", environment: "development", open_at: '2000-01-01 00:00 +09:00', close_at: '2000-01-01 00:00 +09:00')
ar_repo = ReleaseFeature::Repository::ActiveRecordRepository.new(model: model)

client = ReleaseFeature::Client.new(environment: :development, base_repository: yaml_repo, extra_repository: ar_repo)
```

### Caching

In default, repository data is cached 10 min (600sec). Caching time is changed by refresh_interval_sec parameter.

Following exmple is refresh interval is 1 hour.

```ruby
config = { features: { hogehoge_function: { development: { open_at: Time.now, close_at: Time.now + 60 * 60 * 24 * 30 } } } }
hash_repo = ReleaseFeature::Repository::HashRepository.new(hash: config)
client = ReleaseFeature::Client.new(environment: :development, refresh_interval_sec: 60 * 60, base_repository: hash_repo)
# repository data is cached in 1 hour 
```

## Development

After checking out the repo, run `bin/setup` to install dependencies.

Then, run `rake spec` to run the tests.

Then, run `steep check` to run rbs check.

You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the
version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version,
push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/release_feature. This project is
intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to
the [code of conduct](https://github.com/junara/release_feature/blob/master/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the ReleaseFeature project's codebases, issue trackers, chat rooms and mailing lists is expected
to follow the [code of conduct](https://github.com/[USERNAME]/release_feature/blob/master/CODE_OF_CONDUCT.md).
