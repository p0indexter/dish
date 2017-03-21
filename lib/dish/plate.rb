module Dish
  class Plate
    class << self
      def coercions
        @coercions ||= Hash.new(Plate)
      end

      def coerce(key, klass_or_proc)
        coercions[key.to_s] = klass_or_proc
      end
    end

    def initialize(hash)
      Hash[hash.map { |k, v| [k.to_s, v] }]
    end

    def methods(regular = true)
      valid_keys = to_h.keys.map(&:to_sym)
      valid_keys + super
    end

    private

    def _convert(value, coercion)
      case value
      when Array then value.map { |v| _convert(v, coercion) }
      when Hash
        if coercion.is_a?(Proc)
          coercion.call(value)
        else
          coercion.new(value)
        end
      else
        if coercion.is_a?(Proc)
          coercion.call(value)
        else
          value
        end
      end
    end
  end
end
