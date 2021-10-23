# frozen_string_literal: true

module ReleaseFeature
  class FeatureCollection < Hash
    # @param [ReleaseFeature::FeatureCollection] features
    # @return [ReleaseFeature::FeatureCollection]
    def combine_features(features)
      all_names = (names + features.names).uniq
      all_environments = (environments + features.environments).uniq
      all_names.each_with_object(ReleaseFeature::FeatureCollection.new).each do |name, memo_obj|
        memo_obj[name] = build_environments(name, all_environments, features)
      end
    end

    # @return [Array<Symbol>]
    def names
      keys
    end

    # @return [Array<Symbol>]
    def environments
      values.each_with_object([]) { |a, memo| memo.concat(a.keys) }.uniq
    end

    private

    # @param [:Symbol] name
    # @param [:Symbol] environments
    # @param [ReleaseFeature::FeatureCollection] features
    # @return [Hash{Symbol->Hash}]
    def build_environments(name, environments, features)
      environments.each_with_object({}) do |environment, memo_obj|
        next unless build_feature(name, environment, features)

        memo_obj[environment] = build_feature(name, environment, features)
      end
    end

    # @param [:Symbol] name
    # @param [:Symbol] environments
    # @param [ReleaseFeature::FeatureCollection] features
    # @return [ReleaseFeature::Feature]
    def build_feature(name, environment, features)
      if features.dig(name, environment)
        features.dig(name, environment)
      elsif dig(name, environment)
        dig(name, environment)
      end
    end
  end
end
