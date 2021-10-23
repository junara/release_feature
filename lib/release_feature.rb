# frozen_string_literal: true

require 'time'
require 'yaml'
require_relative 'release_feature/version'
require_relative 'release_feature/repository/yaml_repository'
require_relative 'release_feature/repository/active_record_repository'
require_relative 'release_feature/repository/hash_repository'
require_relative 'release_feature/feature'
require_relative 'release_feature/client'
require_relative 'release_feature/feature_collection'

module ReleaseFeature
  class Error < StandardError; end
end
