# frozen_string_literal: true

class ReleaseFeatureItem < ActiveRecord::Base; end

RSpec.describe ReleaseFeature::Repository::ActiveRecordRepository do
  describe '#features' do
    context 'when 1 feature' do
      let(:subject_features) { described_class.new(model: ReleaseFeatureItem).features }

      before do
        create(:release_feature_item,
               name: name, environment: environment, open_at: open_at, close_at: close_at)
      end

      where(:name, :environment, :open_at, :close_at) do
        [
          ['test_feature', 'development', Time.parse('2000-01-01 00:00'), Time.parse('2999-01-01 00:00')],
          ['test_feature', 'development', Time.parse('2000-01-01 00:00'), Time.parse('2999-01-01 00:00')]
        ]
      end

      with_them do
        # it { expect { subject_features }.to change(ReleaseFeatureItem, :count).from(0).to(1) }
        it { expect(subject_features[name.to_sym].keys).to include(environment.to_sym) }
        it { expect(subject_features[name.to_sym][environment.to_sym]).to be_a(ReleaseFeature::Feature) }
        it { expect(subject_features[name.to_sym][environment.to_sym].open_at).to eq open_at }
        it { expect(subject_features[name.to_sym][environment.to_sym].close_at).to eq close_at }
      end
    end

    context 'when include 2 features' do
      let(:subject_features) { described_class.new(model: ReleaseFeatureItem).features }

      let(:hash) do
        {
          test_feature: {
            development: {
              open_at: Time.parse('2000-01-01 00:00'),
              close_at: Time.parse('2999-12-31 23:59')
            },
            production: {
              open_at: Time.parse('2000-01-01 00:00'),
              close_at: Time.parse('2999-12-31 23:59')
            },
            staging: {
              open_at: Time.parse('2000-01-01 00:00'),
              close_at: Time.parse('2999-12-31 23:59')
            }
          },
          test_feature2: {
            development: {
              open_at: Time.parse('2000-01-01 00:00'),
              close_at: Time.parse('2999-12-31 23:59')
            }
          }
        }
      end

      before do
        hash.each do |name, values|
          values.each do |environment, feature|
            create(:release_feature_item,
                   name: name, environment: environment, open_at: feature[:open_at], close_at: feature[:close_at])
          end
        end
      end

      it { expect(subject_features).to be_a(ReleaseFeature::FeatureCollection) }
      it { expect(subject_features).to be_key(:test_feature) }
      it { expect(subject_features).to be_key(:test_feature2) }
      it { expect(subject_features[:test_feature].keys).to include(:development) }
      it { expect(subject_features[:test_feature].keys).to include(:staging) }
      it { expect(subject_features[:test_feature].keys).to include(:production) }
      it { expect(subject_features[:test_feature2].keys).to include(:development) }
      it { expect(subject_features[:test_feature2].keys).not_to include(:production) }
      it { expect(subject_features[:test_feature2].keys).not_to include(:staging) }
      it { expect(subject_features[:test_feature][:development]).to be_a(ReleaseFeature::Feature) }
    end
  end
end
