# frozen_string_literal: true

class ReleaseFeatureItem < ActiveRecord::Base; end

RSpec.describe ReleaseFeature::Client do
  describe '#current_features' do
    let(:yaml_repository) do
      yaml = <<~YAML
        timezone: +09:00
        features:
          test_feature:
            development:
              open_at: 2000-01-01 00:00
              close_at: 2000-12-31 23:59
          test_feature2:
            development:
              open_at: 2010-01-01 00:00
              close_at: 2010-12-31 23:59
      YAML
      filename = Tempfile.new(%w[release_feature_config .yaml]).path
      fp = File.new(filename, 'w')
      fp.write(yaml)
      fp.close

      ReleaseFeature::Repository::YamlRepository.new(path: filename)
    end

    let(:active_record_repository) do
      {
        ar_name => {
          ar_environment => {
            open_at: ar_open_at,
            close_at: ar_close_at
          }
        }
      }.each do |name, values|
        values.each do |environment, feature|
          create(:release_feature_item,
                 name: name, environment: environment, open_at: feature[:open_at], close_at: feature[:close_at])
        end
      end

      ReleaseFeature::Repository::ActiveRecordRepository.new(model: ReleaseFeatureItem)
    end

    after { ReleaseFeatureItem.delete_all }

    where(:ar_name, :ar_environment, :ar_open_at, :ar_close_at, :test_feature_development, :test_feature_production, :test_feature2_development, :test_feature2_production) do
      [
        [:test_feature, :development, Time.parse('2020-01-01 00:00 +09:00'), Time.parse('2020-12-31 23:59 +09:00'),
         Time.parse('2020-01-01 00:00 +09:00'), nil, Time.parse('2010-01-01 00:00 +09:00'), nil],
        [:test_feature2, :development, Time.parse('2020-01-01 00:00 +09:00'), Time.parse('2020-12-31 23:59 +09:00'),
         Time.parse('2000-01-01 00:00 +09:00'), nil, Time.parse('2020-01-01 00:00 +09:00'), nil],
        [:test_feature, :production, Time.parse('2020-01-01 00:00 +09:00'), Time.parse('2020-12-31 23:59 +09:00'),
         Time.parse('2000-01-01 00:00 +09:00'), Time.parse('2020-01-01 00:00 +09:00'), Time.parse('2010-01-01 00:00 +09:00'), nil],
        [:test_feature2, :production, Time.parse('2020-01-01 00:00 +09:00'), Time.parse('2020-12-31 23:59 +09:00'),
         Time.parse('2000-01-01 00:00 +09:00'), nil, Time.parse('2010-01-01 00:00 +09:00'), Time.parse('2020-01-01 00:00 +09:00')]
      ]
    end
    with_them do
      it {
        expect(described_class.new(environment: :development, base_repository: yaml_repository, extra_repository: active_record_repository,
                                   refresh_interval_sec: 60).current_features.dig(:test_feature, :development)&.open_at).to eq test_feature_development
      }

      it {
        expect(described_class.new(environment: :development, base_repository: yaml_repository, extra_repository: active_record_repository,
                                   refresh_interval_sec: 60).current_features.dig(:test_feature, :production)&.open_at).to eq test_feature_production
      }

      it {
        expect(described_class.new(environment: :development, base_repository: yaml_repository, extra_repository: active_record_repository,
                                   refresh_interval_sec: 60).current_features.dig(:test_feature2, :development)&.open_at).to eq test_feature2_development
      }

      it {
        expect(described_class.new(environment: :development, base_repository: yaml_repository, extra_repository: active_record_repository,
                                   refresh_interval_sec: 60).current_features.dig(:test_feature2, :production)&.open_at).to eq test_feature2_production
      }
    end
  end

  describe '#refresh' do
    let(:yaml_repository) do
      yaml = <<~YAML
        timezone: +09:00
        features:
          test_feature:
            development:
              open_at: 2000-01-01 00:00
              close_at: 2000-12-31 23:59
      YAML
      filename = Tempfile.new(%w[release_feature_config .yaml]).path
      fp = File.new(filename, 'w')
      fp.write(yaml)
      fp.close

      ReleaseFeature::Repository::YamlRepository.new(path: filename)
    end

    let(:active_record_repository) do
      {
        test_feature: {
          development: {
            open_at: Time.parse('2020-01-01 00:00 +09:00'),
            close_at: Time.parse('2020-12-31 23:59 +09:00')
          }
        }
      }.each do |name, values|
        values.each do |environment, feature|
          create(:release_feature_item,
                 name: name, environment: environment, open_at: feature[:open_at], close_at: feature[:close_at])
        end
      end

      ReleaseFeature::Repository::ActiveRecordRepository.new(model: ReleaseFeatureItem)
    end
    let(:client) do
      described_class.new(environment: :development, base_repository: yaml_repository, extra_repository: active_record_repository,
                          refresh_interval_sec: 60)
    end

    after { ReleaseFeatureItem.delete_all }

    context 'when not update ReleaseFeatureItem' do
      before do
        client
      end

      it {
        expect(client.current_features.dig(:test_feature, :development)&.open_at).to eq Time.parse('2020-01-01 00:00 +09:00')
      }

      it {
        expect(client.current_features.dig(:test_feature, :development)&.open_at).to eq ReleaseFeatureItem.find_by(name: 'test_feature').open_at
      }
    end

    context 'when after update ReleaseFeatureItem' do
      before do
        client
        ReleaseFeatureItem.find_by(name: 'test_feature').update(
          open_at: Time.parse('2040-01-01 00:00 +09:00'),
          close_at: Time.parse('2040-12-31 23:59 +09:00')
        )
        client.refresh
      end

      after { ReleaseFeatureItem.delete_all }

      it {
        expect(client.current_features.dig(:test_feature, :development)&.open_at).to eq Time.parse('2040-01-01 00:00 +09:00')
      }

      it {
        expect(client.current_features.dig(:test_feature2, :development)&.open_at).to eq nil
      }
    end

    context 'when after create ReleaseFeatureItem' do
      before do
        client
        create :release_feature_item,
               name: 'test_feature2',
               environment: 'development',
               open_at: Time.parse('2040-01-01 00:00 +09:00'),
               close_at: Time.parse('2040-12-31 23:59 +09:00')
        client.refresh
      end

      after { ReleaseFeatureItem.delete_all }

      it {
        expect(client.current_features.dig(:test_feature, :development)&.open_at).to eq Time.parse('2020-01-01 00:00 +09:00')
      }

      it {
        expect(client.current_features.dig(:test_feature2, :development)&.open_at).to eq Time.parse('2040-01-01 00:00 +09:00')
      }
    end
  end
end
