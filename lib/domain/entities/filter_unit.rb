module Domain
  module Entities
    class FilterUnit
      attr_reader :state, :filter_count, :clog_level

      STATES = [:idle, :filtering, :clogged, :cleaning].freeze

      def initialize
        @state = :idle
        @filter_count = 0
        @clog_level = 0
        @clog_threshold = 100
      end

      def filter(juice_volume)
        raise "Filter not idle" unless idle?
        
        @state = :filtering
        @filter_count += 1
        @clog_level += 10
        
        check_clog!
        
        # FIX: Only reset to idle if not clogged
        @state = :idle unless clogged?
        
        juice_volume # Returns filtered juice (same volume for now)
      end

      def check_clog!
        @state = :clogged if @clog_level >= @clog_threshold
      end

      def clean!
        @clog_level = 0
        @state = :idle
      end

      def idle? = state == :idle
      def filtering? = state == :filtering
      def clogged? = state == :clogged
      def cleaning? = state == :cleaning

      def needs_cleaning?
        @clog_level >= (@clog_threshold * 0.8)
      end
    end
  end
end