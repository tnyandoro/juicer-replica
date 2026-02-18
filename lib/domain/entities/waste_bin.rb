module Domain
  module Entities
    class WasteBin
      attr_reader :capacity, :current_waste, :waste_count

      def initialize(capacity_grams: 2000)
        @capacity = capacity_grams
        @current_waste = 0
        @waste_count = 0
      end

      def add_waste(grams)
        #  Validate that grams is positive
        raise ArgumentError, "Grams must be positive" unless grams > 0
        raise ArgumentError, "Bin would overflow" if would_overflow?(grams)
        
        @current_waste += grams
        @waste_count += 1
      end

      def empty!
        @current_waste = 0
      end

      def would_overflow?(grams)
        current_waste + grams > capacity
      end

      def full?
        current_waste >= capacity
      end

      def percentage_full
        return 0.0 if capacity == 0
        ((current_waste.to_f / capacity) * 100).round(2)
      end
    end
  end
end