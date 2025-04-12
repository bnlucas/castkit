# frozen_string_literal: true

require "oj"
require_relative "error"

module Castkit
  module Serialize
    def self.included(base)
      unless base.method_defined?(:to_h) && base.respond_to?(:from_h)
        warn "⚠️  Castkit::Serialize included in a class that may not support .to_h or .from_h"
      end

      base.extend(ClassMethods)
    end

    module ClassMethods
      def oj_options
        @oj_options ||= {
          mode: :rails,
          nilnil: true,
          escape_mode: :json,
          time_format: :xmlschema,
          use_to_hash: true
        }
      end

      def serializer_options(**options)
        @oj_options.merge!(options)
      end

      def from_json(json)
        from_h(::Oj.load(json))
      end

      def cast(obj)
        return obj if obj.is_a?(self)
        return from_json(obj) if obj.is_a?(String)
        return from_h(obj) if obj.is_a?(Hash)

        super if defined?(super)
        raise Castkit::DataObjectError, "Can't cast #{obj.class} to #{name}"
      end
    end

    HAS_TIME_WITH_ZONE = defined?(ActiveSupport::TimeWithZone)

    def to_json(**options)
      options = self.class.oj_options.merge(options)
      hash = normalize_times(to_h)

      ::Oj.dump(hash, options)
    end

    private

    def normalize_times(value)
      case value
      when Array
        value.map { |elem| normalize_times(elem) }
      when Hash
        value.transform_values { |val| normalize_times(val) }
      else
        coerce_time(value)
      end
    end

    def coerce_time(value)
      return value.to_time if HAS_TIME_WITH_ZONE && value.instance_of?(::ActiveSupport::TimeWithZone)

      value
    end
  end
end
