module Domain
  module ValueObjects
    class RipenessLevel
      LEVELS = {
        unripe: { factor: 0.5, description: "Green, less juice" },
        ripe: { factor: 0.8, description: "Optimal juicing" },
        overripe: { factor: 0.7, description: "Soft, more pulp" }
      }.freeze

      attr_reader :level, :factor, :description

      def initialize(level)
        raise ArgumentError, "Invalid ripeness level" unless LEVELS.key?(level)
        @level = level
        @factor = LEVELS[level][:factor]
        @description = LEVELS[level][:description]
      end

      def unripe? = level == :unripe
      def ripe? = level == :ripe
      def overripe? = level == :overripe

      def ==(other)
        other.is_a?(RipenessLevel) && level == other.level
      end
    end
  end
end