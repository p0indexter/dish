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
      @hash = Hash[hash.map { |k, v| [k.to_s, v] }]
      @cache = Hash.new do |cache, key|
        cache[key] = _convert(@hash[key], self.class.coercions[key])
      end
    end

    def hash
      to_h.hash
    end

    def ==(other)
      return false unless other.respond_to?(:to_h)
      to_h == other.to_h
    end

    alias :eql? :==

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

    def to_h
      hash
    end

    def to_json(*args)
      # If we're using RubyMotion #to_json isn't available like with Ruby's JSON stdlib
      if defined?(Motion::Project::Config)
        # From BubbleWrap: https://github.com/rubymotion/BubbleWrap/blob/master/motion/core/json.rb#L30-L32
        NSJSONSerialization.dataWithJSONObject(to_h, options: 0, error: nil).to_str
      elsif defined?(JSON)
        to_h.to_json(*args)
      else
        raise "#{self.class}#to_json depends on Hash#to_json. Try again after using `require 'json'`."
      end
    end

    def methods(regular = true)
      valid_keys = to_h.keys.map(&:to_sym)
      valid_keys + super
    end

    private

    attr_reader :hash
    attr_reader :cache

    def _get(key)
      cache[key]
    end

    def _set(key, value)
      cache.delete(key)
      hash[key] = value
    end

    def _key?(key)
      hash.key?(key)
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
