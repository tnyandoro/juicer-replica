module Domain
  module ValueObjects
    class FruitSize
      SIZES = {
        small: { weight_range: 80..120, juice_factor: 0.4 },
        medium: { weight_range: 121..180, juice_factor: 0.5 },
        large: { weight_range: 181..250, juice_factor: 0.6 }
      }.freeze

      attr_reader :size, :weight_range, :juice_factor

      def initialize(size)
        raise ArgumentError, "Invalid fruit size" unless SIZES.key?(size)
        @size = size
        @weight_range = SIZES[size][:weight_range]
        @juice_factor = SIZES[size][:juice_factor]
      end

      def small? = size == :small
      def medium? = size == :medium
      def large? = size == :large

      def ==(other)
        other.is_a?(FruitSize) && size == other.size
      end
    end
  end
end