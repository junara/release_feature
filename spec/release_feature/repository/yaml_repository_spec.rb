# frozen_string_literal: true

RSpec.describe ReleaseFeature::Repository::YamlRepository do
  describe '#features' do
    context 'when 1 feature' do
      let(:subject_features) { described_class.new(path: filename).features }
      let(:yaml) do
        <<~YAML
          timezone: #{yaml_timezone}
          features:
            #{yaml_name}:
              #{yaml_environment}:
                open_at: #{yaml_open_at}
                close_at: #{yaml_close_at}
        YAML
      end
      let(:filename) { Tempfile.new(%w[release_feature_config .yaml]).path }

      before do
        fp = File.new(filename, 'w')
        fp.write(yaml)
        fp.close
      end

      where(:yaml_timezone, :yaml_name, :yaml_environment, :yaml_open_at, :yaml_close_at, :open_at, :close_at) do
        [
          ['+09:00', 'test_feature', 'development', '2000-01-01 00:00', '2999-01-01 00:00',
           Time.new(2000, 1, 1, 0, 0, 0, '+09:00'), Time.new(2999, 1, 1, 0, 0, 0, '+09:00')],
          ['+08:00', 'test_feature', 'development', '2000-01-01 00:00', '2999-01-01 00:00',
           Time.new(2000, 1, 1, 0, 0, 0, '+08:00'), Time.new(2999, 1, 1, 0, 0, 0, '+08:00')]
        ]
      end

      with_them do
        it { expect(subject_features[yaml_name.to_sym].keys).to include(yaml_environment.to_sym) }
        it { expect(subject_features[yaml_name.to_sym][yaml_environment.to_sym]).to be_a(ReleaseFeature::Feature) }
        it { expect(subject_features[yaml_name.to_sym][yaml_environment.to_sym].open_at).to eq open_at }
        it { expect(subject_features[yaml_name.to_sym][yaml_environment.to_sym].close_at).to eq close_at }
      end
    end

    context 'when include 2 features' do
      let(:yaml) do
        <<~YAML
          timezone: +09:00
          features:
            test_feature:
              development:
                open_at: 2000-01-01 00:00
                close_at: 2999-12-31 23:59
              production:
                open_at: 2000-01-01 00:00
                close_at: 2999-12-31 23:59
              staging:
                open_at: 2000-01-01 00:00
                close_at: 2999-12-31 23:59
            test_feature2:
              development:
                open_at: 2000-01-01 00:00
                close_at: 2999-12-31 23:59
        YAML
      end
      let(:subject_features) { described_class.new(path: filename).features }
      let(:filename) { Tempfile.new(%w[release_feature_config .yaml]).path }

      before do
        fp = File.new(filename, 'w')
        fp.write(yaml)
        fp.close
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
