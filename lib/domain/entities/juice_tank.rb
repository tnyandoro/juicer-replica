require_relative '../value_objects/juice_volume'

module Domain
  module Entities
    class JuiceTank
      attr_reader :capacity, :current_volume, :juice_count

      def initialize(capacity_ml: 5000)
        @capacity = ValueObjects::JuiceVolume.new(capacity_ml)
        @current_volume = ValueObjects::JuiceVolume.new(0)
        @juice_count = 0
      end

      def add_juice(volume)
        raise ArgumentError, "Tank would overflow" if would_overflow?(volume)
        @current_volume = current_volume + volume
        @juice_count += 1
      end

      def empty!
        @current_volume = ValueObjects::JuiceVolume.new(0)
      end

      def would_overflow?(volume)
        (current_volume + volume).milliliters > capacity.milliliters
      end

      def full?
        current_volume.milliliters >= capacity.milliliters
      end

      def percentage_full
        ((current_volume.milliliters / capacity.milliliters) * 100).round(2)
      end
    end
  end
end