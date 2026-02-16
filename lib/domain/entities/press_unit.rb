module Domain
  module Entities
    class PressUnit
      attr_reader :state, :press_count, :last_press_time

      STATES = [:idle, :pressing, :error].freeze

      def initialize
        @state = :idle
        @press_count = 0
        @last_press_time = nil
        @efficiency_factor = 0.9
      end

      def press(fruit)
        raise "Press unit not idle" unless idle?
        
        @state = :pressing
        @last_press_time = Time.now
        juice = fruit.potential_juice_volume(@efficiency_factor)
        waste = fruit.potential_waste(@efficiency_factor)
        @press_count += 1
        @state = :idle
        
        { juice: juice, waste: waste }
      end

      def idle? = state == :idle
      def pressing? = state == :pressing
      def error? = state == :error

      def trigger_error
        @state = :error
      end

      def reset
        @state = :idle
      end

      def efficiency
        @efficiency_factor
      end
    end
  end
end