# frozen_string_literal: true

require 'tzinfo'
module ReleaseFeature
  module Repository
    class YamlRepository
      class AccessibleRange
        attr_reader :open_at, :close_at

        def initialize(open_at:, close_at:)
          @open_at = open_at
          @close_at = close_at
        end
      end

      # @param [String] path
      def initialize(path:)
        @path = path
      end

      # @return [ReleaseFeature::FeatureCollection]
      def features
        data = YAML.load_file(@path)
        convert_to_feature_collection(data)
      end

      private

      # @param [Hash] data
      # @return [ReleaseFeature::FeatureCollection]
      def convert_to_feature_collection(data)
        timezone = data['timezone']
        features = data['features']
        symbolize_features(features, timezone)
      end

      # @param [Hash] features
      # @return [ReleaseFeature::FeatureCollection]
      def symbolize_features(features, timezone)
        features.each_with_object(ReleaseFeature::FeatureCollection.new) do |(name, environments), memo_obj|
          environments.each do |environment, range|
            if memo_obj[name.to_sym]
              memo_obj[name.to_sym][environment.to_sym] = build_feature(name, environment, range, timezone)
            else
              memo_obj[name.to_sym] = { environment.to_sym => build_feature(name, environment, range, timezone) }
            end
          end
        end
      end

      # @param [Str] name
      # @param [Str] environment
      # @param [Hash] range
      # @param [String] timezone
      # @return [ReleaseFeature::Feature]
      def build_feature(name, environment, range, timezone)
        accessible_range = to_range_struct(range, timezone)
        ReleaseFeature::Feature.new(
          name: name.to_sym,
          environment: environment.to_sym,
          open_at: accessible_range.open_at,
          close_at: accessible_range.close_at
        )
      end

      # @param [Hash] range
      # @param [String] timezone
      # @return [AccessibleRange]
      def to_range_struct(range, timezone)
        AccessibleRange.new(
          open_at: cast_to_time(range['open_at'], timezone),
          close_at: cast_to_time(range['close_at'], timezone)
        )
      end

      # @param [String] str
      # @param [String] timezone
      # @return [Time]
      def cast_to_time(str, timezone)
        time = Time.parse(str)
        year = time.year
        month = time.month
        day = time.day
        hour = time.hour
        minute = time.min
        Time.new(year, month, day, hour, minute, 0, timezone)
      end
    end
  end
end
