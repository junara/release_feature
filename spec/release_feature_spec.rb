# frozen_string_literal: true

RSpec.describe ReleaseFeature do
  it 'has a version number' do
    expect(ReleaseFeature::VERSION).not_to be nil
  end

  it { expect(YAML.class).to eq(Module) }
  it { expect(Time.class).to eq(Class) }
end
