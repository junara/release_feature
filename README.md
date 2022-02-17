[![codecov](https://codecov.io/gh/junara/release_feature/branch/main/graph/badge.svg?token=2EM2TNEVN6)](https://codecov.io/gh/junara/release_feature)

# ReleaseFeature

ReleaseFeature is feature toggle.

## Installation

Using bundler, please add following line to your Gemfile.

```ruby
gem 'release_feature'
```

Using gem

```shell
gem install release_feature
```

If you want to use latest main branch, please add following line to Gemfile.

```ruby
gem 'release_feature', git: 'https://github.com/junara/release_feature.git', branch: 'main'
```

And then execute:

    $ bundle install

## Usage

Prepare client by configuring repository and initialize client.

You can select 4 repository types. From yaml (YamlRepository), hash (HashRepository) or ActiveRecord (
ActiveRecordRepository).

Client can have maximum 2 repositories (called to `base_repository` and `extra_repository`). extra_repository is
optional.

If `extra_repository` is set, `base_repository` is merged by `extra_repository`. `extra_repository` setting has priority

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
timezone: +09:00
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

Set `zone` to `timezone` . `zone` is defined in https://docs.ruby-lang.org/en/3.1/Time.html

> zone: a timezone, which may be:
> A string offset from UTC.
> A single letter offset from UTC, in the range 'A'..'Z', 'J' (the so-called military timezone) excluded.
> An integer number of seconds.
> A timezone object; see Timezone Argument for details.

```ruby
path = 'release_feature_config.yml'
yaml_repo = ReleaseFeature::Repository::YamlRepository.new(path: path)
development_client = ReleaseFeature::Client.new(environment: :development, base_repository: yaml_repo)
development_client.permitted?(:hoge_feature) #=> true

staging_client = ReleaseFeature::Client.new(environment: :staging, base_repository: yaml_repo)
staging_client.permitted?(:hoge_feature) #=> false

```

### Using ActiveRecord repository

Model have four attributes (name (:string), environment (:string), open_at (:datetime), close_at (:datetime)

You cac migrate model by command line.

```shell
rails g model ReleaseFeatureItem name:string environment:string open_at:datetime close_at:datetime
```

Above command create following migration file.

```ruby

class CreateReleaseFeatureItems < ActiveRecord::Migration[7.0]
  def change
    create_table :release_feature_items do |t|
      t.string :name
      t.string :environment
      t.datetime :open_at
      t.datetime :close_at

      t.timestamps
    end
  end
end

```

And run migrate.

```shell
rails db:migrate

```

Using created ActiveRecord for `base_repository` like this.

```ruby
model = ReleaseFeatureItem # migrated by active_record
ReleaseFeatureItem.create!(name: 'hoge_feature', environment: 'development', open_at: '2000-01-01 00:00 +09:00', close_at: '2002-01-01 00:00 +09:00')
ar_repo = ReleaseFeature::Repository::ActiveRecordRepository.new(model: model)
client = ReleaseFeature::Client.new(environment: :development, base_repository: ar_repo)
client.permitted?(:hoge_feature) #=> false

```

### Using "extra_repository"

Document under Construction

`extra_repository` overrides `base_repository`.

ex)

`base_repository` is yaml repository. `extra_repository` is ActiveRecord repository.

```ruby
path = 'release_feature_config.yml'
yaml_repo = ReleaseFeature::Repository::YamlRepository.new(path: path)

model = ReleaseFeatureItem # migrated by active_record

ReleaseFeatureItem.create!(name: 'hoge_feature', environment: 'development', open_at: '2000-01-01 00:00 +09:00', close_at: '2002-01-01 00:00 +09:00')
ar_repo = ReleaseFeature::Repository::ActiveRecordRepository.new(model: model)

client = ReleaseFeature::Client.new(environment: :development, base_repository: yaml_repo, extra_repository: ar_repo)

# activerecord_repository override yaml_repository hoge_feature.
client.permitted?(:hoge_feature) #=> false

release_feature_item = ReleaseFeatureItem.find_by(name: 'hoge_feature', environment: 'development')
release_feature_item.update(close_at: '2099-01-01 00:00 +09:00')

# Default caching time (10 min) later

client.permitted?(:hoge_feature) #=> true

```

### Caching

In default, repository data is cached 10 min (600sec). Caching time is changed by `refresh_interval_sec` parameter.

Following exmple, refresh interval is 1 hour (60 * 60 = 3600 sec ).

```ruby
config = { features: { hogehoge_function: { development: { open_at: Time.now, close_at: Time.now + 60 * 60 * 24 * 30 } } } }
hash_repo = ReleaseFeature::Repository::HashRepository.new(hash: config)
client = ReleaseFeature::Client.new(environment: :development, refresh_interval_sec: 60 * 60, base_repository: hash_repo)

client.permitted?(:hoge_feature) #=> true
# Repository data is cached and is not loaded for 1 hour (60 * 60 sec).

```

### With Rails app

In Ruby on Rails app, Bt Yaml repository, you can use like this.

```ruby

class YourAppFlag
  include Singleton

  def initialize(environment = nil, path:)
    environment ||= Rails.env
    yaml_repo = ReleaseFeature::Repository::YamlRepository.new(path: path)
    @client = ReleaseFeature::Client.new(environment: environment.to_sym, base_repository: yaml_repo)
  end

  def permitted?(feature)
    @client.permitted?(feature.to_sym)
  end

  def run_if_permitted
    return unless permitted?
    yield
  end
end

# Before use, please prepare 'release_feature_config.yml'. See above.
flag = YourAppFlag.instance.new(path: 'release_feature_config.yml')

# Using simple boolean flag.
if flag.permitted?(:hoge_feature)
  put 'run if permitted.'
end

# Using block
flag.run_if_permitted do
  put 'run if permitted.'
end

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
