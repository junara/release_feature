# frozen_string_literal: true

module ReleaseFeature
  module Repository
    class HashRepository
      # @param [Hash] hash
      def initialize(hash:)
        @hash = hash
      end

      # @return [ReleaseFeature::FeatureCollection]
      def features
        data = @hash
        convert_to_feature_collection(data)
      end

      private

      # @param [Hash] data
      # @return [ReleaseFeature::FeatureCollection]
      def convert_to_feature_collection(data)
        data[:features].each_with_object(ReleaseFeature::FeatureCollection.new) do |(name, environments), memo_obj|
          memo_obj[name] = {}
          environments.each do |environment, range|
            memo_obj[name][environment] = build_feature(name, environment, range[:open_at], range[:close_at])
          end
        end
      end

      # @param [Symbol] name
      # @param [Symbol] environment
      # @param [Time] open_at
      # @param [Time] close_at
      # @return [ReleaseFeature::Feature]
      def build_feature(name, environment, open_at, close_at)
        ReleaseFeature::Feature.new(
          name: name,
          environment: environment,
          open_at: open_at,
          close_at: close_at
        )
      end
    end
  end
end
