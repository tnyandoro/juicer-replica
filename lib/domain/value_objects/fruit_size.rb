module Domain
  module ValueObjects
    class FruitSize
      attr_reader :size, :weight_range, :juice_factor

      SIZES = {
        small: { weight_range: 80..120, juice_factor: 0.4 },
        medium: { weight_range: 121..180, juice_factor: 0.5 },
        large: { weight_range: 181..250, juice_factor: 0.6 }
      }.freeze

      def initialize(size)
        @size = size.to_sym
        config = SIZES[@size]
        
        raise ArgumentError, "Unknown size: #{size}. Valid sizes: #{SIZES.keys.join(', ')}" unless config
        
        @weight_range = config[:weight_range]
        @juice_factor = config[:juice_factor]
      end

      def small?
        @size == :small
      end

      def medium?
        @size == :medium
      end

      def large?
        @size == :large
      end

      def type
        @size
      end

      def ==(other)
        other.is_a?(FruitSize) && size == other.size
      end

      def to_s
        size.to_s.capitalize
      end
    end
  end
end