# frozen_string_literal: true

module ReleaseFeature
  module Repository
    class ActiveRecordRepository
      # @param [Class] model
      def initialize(model:)
        @model = model
      end

      # @return [ReleaseFeature::FeatureCollection]
      def features
        data = @model.all
        convert_to_feature_collection(data)
      end

      private

      # @param [ActiveRecord] data
      # @return [ReleaseFeature::FeatureCollection]
      def convert_to_feature_collection(data)
        data.each_with_object(ReleaseFeature::FeatureCollection.new) do |record, memo_obj|
          name_key = record.name.to_sym
          environment_key = record.environment.to_sym
          feature = build_feature(record)
          if memo_obj[name_key].nil?
            memo_obj[name_key] = { environment_key => feature }
          else
            memo_obj[name_key][environment_key] = feature
          end
        end
      end

      # @param [ActiveRecord] record
      # @return [ReleaseFeature::Feature]
      def build_feature(record)
        ReleaseFeature::Feature.new(
          name: record.name,
          environment: record.environment,
          open_at: record.open_at,
          close_at: record.close_at
        )
      end
    end
  end
end
