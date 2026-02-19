module Domain
  module Entities
    class FilterUnit
      attr_reader :state, :filter_count, :clog_level, :wear_level

      STATES = [:idle, :filtering, :clogged, :maintenance_required].freeze
      CLOG_THRESHOLD = 80
      MAX_FILTER_COUNT = 500
      WEAR_PER_FILTER = 0.2
      CLOG_PER_FILTER = 5

      def initialize
        @state = :idle
        @filter_count = 0
        @clog_level = 0.0
        @wear_level = 0.0
      end

      def filter(juice_volume)
        raise "Filter not idle" unless idle?
        raise "Filter clogged" if clogged?
        raise "Filter needs replacement" if needs_replacement?
        
        @state = :filtering
        
        begin
          @filter_count += 1
          @wear_level = (@wear_level + WEAR_PER_FILTER).clamp(0, 100)
          
          # Calculate filtration efficiency based on wear
          @filtration_efficiency = [1.0 - (@wear_level / 200.0), 0.8].max
          
          # Apply efficiency to output
          filtered_volume = juice_volume.milliliters * @filtration_efficiency
          
          # Increase clog level
          @clog_level = (@clog_level + CLOG_PER_FILTER).clamp(0, 100)
          check_clog!
          
          Domain::ValueObjects::JuiceVolume.new(filtered_volume)
        rescue => e
          @state = :error
          raise e
        ensure
          @state = :idle if @state == :filtering
        end
      end

      def check_clog!
        @state = :clogged if @clog_level >= CLOG_THRESHOLD
      end

      def clean!
        @clog_level = 0.0
        @state = :idle
      end

      def idle? = state == :idle
      def filtering? = state == :filtering
      def clogged? = state == :clogged
      def needs_replacement? = @filter_count >= MAX_FILTER_COUNT || @wear_level >= 100

      def needs_cleaning?
        @clog_level >= 80
      end

      def replace_filter
        @wear_level = 0.0
        @filter_count = 0
        @clog_level = 0.0
        @filtration_efficiency = 1.0
        @state = :idle
      end

      def needs_maintenance?
        needs_replacement? || clogged?
      end

      def wear_percentage
        @wear_level.round(2)
      end

      # ✅ FIX: Calculate efficiency on-demand (not just from instance variable)
      def filtration_efficiency_percentage
        efficiency = @filtration_efficiency || [1.0 - (@wear_level / 200.0), 0.8].max
        (efficiency * 100).round(2)
      end
    end
  end
end