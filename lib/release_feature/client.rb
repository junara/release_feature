# frozen_string_literal: true

module ReleaseFeature
  class Client
    attr_reader :updated_at

    # @param [String, Symbol] environment
    # @param [ActiveRecordRepository, YamlRecordRepository, HashRecordRepository] base_repository
    # @param [nil] extra_repository
    # @param [Integer] refresh_interval_sec
    def initialize(environment:, base_repository:, extra_repository: nil, refresh_interval_sec: 600)
      @environment = environment.to_sym
      @base_repository = base_repository
      @extra_repository = extra_repository
      @refresh_interval_sec = if refresh_interval_sec.is_a?(Integer)
                                refresh_interval_sec
                              else
                                raise ReleaseFeature::Error, 'refresh_interval_sec must be Integer'
                              end
      load_features
    end

    # @param [Symbol] feature_name
    # @param [TrueClass, FalseClass] time
    def permitted?(feature_name, time: nil)
      time ||= Time.now

      refresh if expired?(time)

      name = feature_name.to_sym
      raise ReleaseFeature::Error, "#{feature_name} is not registered." if @features[feature_name.to_sym].nil?

      feature = to_feature(@features, name, @environment)
      return false if feature.nil?

      feature.permitted?(time)
    end

    def current_features
      @features
    end

    def refresh
      load_features
      true
    rescue StandardError => e
      e.message
      # errorがある場合は@featuresを更新しない
      false
    end

    def names
      @features.names
    end

    def environments
      @features.environments
    end

    private

    def to_feature(features, name, environment)
      features.dig(name, environment)
    end

    def expired?(time = nil)
      time ||= Time.now
      raise ReleaseFeature::Error, 'current_time is must be Time class' unless time.is_a?(Time)

      @updated_at + @refresh_interval_sec < time
    end

    def load_features
      features = if @extra_repository
                   @base_repository.features.combine_features(@extra_repository.features)
                 else
                   @base_repository.features
                 end
      @features = features
      @updated_at = Time.now
    end
  end
end
