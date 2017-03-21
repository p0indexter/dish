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

    def initialize(json)
      @hash = Hash[json.map { |k, v| [k.to_s, v] }]
      @cache = Hash.new do |cache, key|
        cache[key] = _convert(@hash[key], self.class.coercions[key])
      end
    end

    def method_missing(method, *args, &block)
      method = method.to_s
      key = method[0..-2]
      if method.end_with?("?")
        !!_get(key)
      elsif method.end_with? '='
        _set(key, args.first)
      else
        _get(method)
      end
    end

    def respond_to_missing?(method, *args)
      _key?(method.to_s) || super
    end

    def to_direct
      @hash
    end



    def methods(regular = true)
      valid_keys = to_direct.keys.map(&:to_sym)
      valid_keys + super
    end

    private

    def _get(key)
      @cache[key]
    end

    def _set(key, value)
      @cache.delete(key)
      @hash[key] = value
    end

    def _key?(key)
      @hash.key?(key)
    end

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
