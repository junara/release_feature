# frozen_string_literal: true

FactoryBot.define do
  factory :release_feature_item do
    name { 'test_feature' }
    environment { 'development' }
    open_at { Time.parse('2000-01-01 00:00') }
    close_at { Time.parse('2099-12-31 23:59') }
  end
end
