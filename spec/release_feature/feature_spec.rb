# frozen_string_literal: true

require 'date'
RSpec.describe ReleaseFeature::Feature do
  let(:feature_params) do
    {
      name: name,
      environment: environment,
      open_at: open_at,
      close_at: close_at
    }
  end

  describe '#new' do
    context 'when valid data' do
      where(:name, :environment, :open_at, :close_at) do
        [
          [:test_feature, :development, Time.new(2000, 1, 1, 0, 0, 0, '+09:00'), Time.new(2000, 1, 1, 0, 1, 0, '+09:00')]
        ]
      end
      with_them do
        it { expect { described_class.new(**feature_params) }.not_to raise_error }
      end
    end

    context 'when one of attributes is nil' do
      where(:name, :environment, :open_at, :close_at) do
        [
          [nil, :development, Time.new(2000, 1, 1, 0, 0, 0, '+09:00'), Time.new(2000, 1, 1, 0, 1, 0, '+09:00')],
          [:test_feature, nil, Time.new(2000, 1, 1, 0, 0, 0, '+09:00'), Time.new(2000, 1, 1, 0, 1, 0, '+09:00')],
          [:test_feature, :development, nil, Time.new(2000, 1, 1, 0, 1, 0, '+09:00')],
          [:test_feature, :development, Time.new(2000, 1, 1, 0, 0, 0, '+09:00'), nil]
        ]
      end
      with_them do
        it { expect { described_class.new(**feature_params) }.to raise_error ReleaseFeature::Error }
      end
    end

    context 'when range is invalid' do
      where(:name, :environment, :open_at, :close_at) do
        [
          [:test_feature, :development, Time.new(2000, 1, 1, 0, 0, 0, '+09:00'), Time.new(2000, 1, 1, 0, 0, 0, '+09:00')],
          [:test_feature, :development, Time.new(2000, 1, 1, 0, 0, 0, '+09:00'), Time.new(1999, 12, 31, 23, 59, 0, '+09:00')]

        ]
      end
      with_them do
        it { expect { described_class.new(**feature_params) }.to raise_error ReleaseFeature::Error }
      end
    end

    context 'when name or environment type is Integer' do
      where(:name, :environment, :open_at, :close_at) do
        [
          [1, :development, Time.new(2000, 1, 1, 0, 0, 0, '+09:00'), Time.new(2000, 1, 1, 0, 1, 0, '+09:00')],
          [:test_feature, 1, Time.new(2000, 1, 1, 0, 0, 0, '+09:00'), Time.new(2000, 1, 1, 0, 1, 0, '+09:00')]

        ]
      end
      with_them do
        it { expect { described_class.new(**feature_params) }.to raise_error ReleaseFeature::Error }
      end
    end

    context 'when open_at or close_at type is Date' do
      where(:name, :environment, :open_at, :close_at) do
        [
          [:test_feature, :development, Date.new(1999, 1, 1), Time.new(2000, 1, 1, 0, 1, 0, '+09:00')],
          [:test_feature, :development, Time.new(2000, 1, 1, 0, 0, 0, '+09:00'), Date.new(2099, 1, 1)]

        ]
      end
      with_them do
        it { expect { described_class.new(**feature_params) }.to raise_error ReleaseFeature::Error }
      end
    end
  end

  # rubocop:disable Naming/VariableNumber
  describe '#name_error_message' do
    let(:environment) { :development }
    let(:open_at) { Time.new(2000, 1, 1, 0, 0, 0, '+09:00') }
    let(:close_at) { Time.new(2000, 1, 1, 0, 1, 0, '+09:00') }

    context 'when valid name' do
      where(:name) do
        [
          [:date_123]
        ]
      end
      with_them do
        it { expect { described_class.new(**feature_params) }.not_to raise_error }
      end
    end

    context 'when invalid name' do
      where(:name) do
        [
          [:'date 123'], # not permitted space.
          [:Date_123], # not permitted uppercase.
          [:date_12], # not permitted lower than 8 length.
          [:'1date_12'], # not permitted starting with integer.
          [:ｄate_123] # not permitted full-width
        ]
      end
      with_them do
        it { expect { described_class.new(**feature_params) }.to raise_error ReleaseFeature::Error }
      end
    end
  end
  # rubocop:enable Naming/VariableNumber

  describe '#permitted?' do
    let(:name) { :test_feature }
    let(:environment) { :development }

    where(:open_at, :close_at, :current_time, :result) do
      [
        [Time.new(2000, 1, 1, 0, 10, 0, '+09:00'), Time.new(2000, 1, 1, 0, 12, 0, '+09:00'), Time.new(2000, 1, 1, 0, 9, 0, '+09:00'), false],
        [Time.new(2000, 1, 1, 0, 10, 0, '+09:00'), Time.new(2000, 1, 1, 0, 12, 0, '+09:00'), Time.new(2000, 1, 1, 0, 9, 59, '+09:00'), false],
        [Time.new(2000, 1, 1, 0, 10, 0, '+09:00'), Time.new(2000, 1, 1, 0, 12, 0, '+09:00'), Time.new(2000, 1, 1, 0, 10, 0, '+09:00'), true],
        [Time.new(2000, 1, 1, 0, 10, 0, '+09:00'), Time.new(2000, 1, 1, 0, 12, 0, '+09:00'), Time.new(2000, 1, 1, 0, 11, 0, '+09:00'), true],
        [Time.new(2000, 1, 1, 0, 10, 0, '+09:00'), Time.new(2000, 1, 1, 0, 12, 0, '+09:00'), Time.new(2000, 1, 1, 0, 11, 59, '+09:00'), true],
        [Time.new(2000, 1, 1, 0, 10, 0, '+09:00'), Time.new(2000, 1, 1, 0, 12, 0, '+09:00'), Time.new(2000, 1, 1, 0, 12, 0, '+09:00'), false],
        [Time.new(2000, 1, 1, 0, 10, 0, '+09:00'), Time.new(2000, 1, 1, 0, 12, 0, '+09:00'), Time.new(2000, 1, 1, 0, 13, 0, '+09:00'), false]
      ]
    end
    with_them do
      it { expect(described_class.new(**feature_params).permitted?(current_time)).to eq result }
    end
  end
end
