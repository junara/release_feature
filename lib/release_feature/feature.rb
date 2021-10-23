# frozen_string_literal: true

module ReleaseFeature
  class Feature
    attr_reader :name, :environment, :open_at, :close_at, :errors

    # @param [String, Symbol] name
    # @param [String, Symbol] environment
    # @param [Time] open_at
    # @param [Time] close_at
    def initialize(name:, environment:, open_at:, close_at:)
      validate_present({ name: name, environment: environment, open_at: open_at, close_at: close_at })
      @name = cast_to_sym(:name, name)
      @environment = cast_to_sym(:environment, environment)
      @open_at = open_at
      @close_at = close_at
      raise ReleaseFeature::Error, errors_full_message unless valid?
    end

    # @param [Time] current_time
    # @return [TrueClass, FalseClass]
    def permitted?(current_time)
      (open_at...close_at).cover?(current_time)
    end

    private

    # @return [TrueClass, FalseClass]
    def valid?
      initialize_errors
      validate_all
      @errors.size.zero?
    end

    def validate_present(attrs)
      attrs.each do |k, v|
        if v.nil?
          raise ReleaseFeature::Error,
                "#{k} must be present."
        end
      end
    end

    def validate_all
      validate_name
      validate_open_at
      validate_close_at
      validate_range
    end

    def errors_full_message
      @errors.join(' ')
    end

    def initialize_errors
      @errors = []
    end

    # @param [String, Symbol] attr_name
    # @param [Object] val
    # @param [String] message
    def add_error(attr_name, val, message)
      @errors << "#{val} of #{attr_name} has error. #{message}"
    end

    def validate_name
      message = name_error_message(name)
      return unless message

      add_error('name', name, message)
    end

    def validate_open_at
      return if time_present?(open_at)

      add_error('open_at', open_at, 'set time to open_at.')
    end

    def validate_close_at
      return if time_present?(close_at)

      add_error('close_at', close_at, 'set time to close_at.')
    end

    def validate_range
      return if open_at < close_at

      add_error('open_at', open_at, 'open_at is less than close_at.')
      add_error('close_at', close_at, 'close_at is more than open_at.')
    end

    # @param [String] attr
    def time_present?(attr)
      attr.is_a?(Time)
    end

    # @param [Symbol] key
    # @param [String, Symbol] str
    def cast_to_sym(key, str)
      raise ReleaseFeature::Error, "#{key} must be String or Symbol" unless str.is_a?(String) || str.is_a?(Symbol)

      str.to_sym
    end

    # @param [String, Symbol] name
    # @return [String, NilClass]
    def name_error_message(name)
      if name.to_s.match?(/\s/)
        'space is not permitted to name.'
      elsif name.to_s.size < 8
        'more than 7 character is permitted to name.'
      elsif !name.to_s.match?(/^[a-z]([a-z0-9_]{7,})$/)
        ' 0-9 or a-z or _ is permitted to name.'
      end
    end
  end
end
