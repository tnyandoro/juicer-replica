module Domain
  module ValueObjects
    class JuiceVolume
      attr_reader :milliliters

      def initialize(milliliters)
        raise ArgumentError, "Volume cannot be negative" if milliliters < 0
        @milliliters = milliliters.round(2)
      end

      def +(other)
        JuiceVolume.new(milliliters + other.milliliters)
      end

      def -(other)
        JuiceVolume.new([milliliters - other.milliliters, 0].max)
      end

      def *(factor)
        JuiceVolume.new(milliliters * factor)
      end

      def zero? = milliliters == 0

      def to_s = "#{milliliters} ml"

      def ==(other)
        other.is_a?(JuiceVolume) && milliliters == other.milliliters
      end
    end
  end
end