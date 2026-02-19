module Domain
  module Entities
    class PressUnit
      attr_reader :state, :press_count, :last_press_time, :wear_level

      STATES = [:idle, :pressing, :error, :maintenance_required].freeze
      MAX_PRESS_COUNT = 1000
      WEAR_PER_PRESS = 0.1

      def initialize
        @state = :idle
        @press_count = 0
        @last_press_time = nil
        @wear_level = 0.0
        @efficiency = 1.0
      end

      def press(fruit)
        raise "Press unit not idle" unless idle?
        raise "Press unit needs maintenance" if maintenance_required?
        
        @state = :pressing
        @last_press_time = Time.now
        
        begin
          # Apply wear
          @wear_level = (@wear_level + WEAR_PER_PRESS).clamp(0, 100)
          
          # Calculate efficiency based on wear
          @efficiency = [1.0 - (@wear_level / 100.0), 0.5].max
          
          # Get juice with efficiency applied
          juice = fruit.potential_juice_volume
          waste = fruit.potential_waste
          
          # Apply efficiency to juice output
          adjusted_juice = Domain::ValueObjects::JuiceVolume.new(
            juice.milliliters * @efficiency
          )
          
          # Only increment on success
          @press_count += 1
          
          { juice: adjusted_juice, waste: waste }
        rescue => e
          @state = :error
          raise e
        ensure
          # ✅ FIX: Reset to idle if we were pressing (regardless of error state)
          @state = :idle if @state == :pressing || @state == :error
        end
      end

      def idle? = state == :idle
      def pressing? = state == :pressing
      def error? = state == :error
      def maintenance_required? = state == :maintenance_required || @press_count >= MAX_PRESS_COUNT

      def trigger_error
        @state = :error
      end

      def reset
        @state = :idle
      end

      def perform_maintenance
        @wear_level = 0.0
        @efficiency = 1.0
        @press_count = 0
        @state = :idle
      end

      def needs_maintenance?
        @press_count >= MAX_PRESS_COUNT || @wear_level >= 100
      end

      def wear_percentage
        @wear_level.round(2)
      end

      def efficiency_percentage
        (@efficiency * 100).round(2)
      end
    end
  end
end