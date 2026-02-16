require 'securerandom'
require_relative '../value_objects/fruit_size'
require_relative '../value_objects/ripeness_level'
require_relative '../value_objects/juice_volume'

module Domain
  module Entities
    class Fruit
      # Juice density approximation (g/ml)
      # Citrus juice density: ~1.04 g/ml (slightly denser than water)
      # For simulation simplicity, we use 1.0 g/ml approximation
      JUICE_DENSITY = 1.0 # g/ml

      attr_reader :id, :type, :size, :ripeness, :weight

      def initialize(type:, size:, ripeness:, weight: nil)
        @id = SecureRandom.uuid
        @type = type # :orange, :lemon, :grapefruit
        
        # Convert to value objects FIRST before using their methods
        @size = size.is_a?(ValueObjects::FruitSize) ? size : ValueObjects::FruitSize.new(size)
        @ripeness = ripeness.is_a?(ValueObjects::RipenessLevel) ? ripeness : ValueObjects::RipenessLevel.new(ripeness)
        
        # Now we can safely access weight_range
        @weight = weight || rand(@size.weight_range)
      end

      def potential_juice_volume(efficiency_factor = 0.9)
        # Formula: weight * ripeness_factor * juice_factor * efficiency
        # Result is in milliliters (ml)
        juice_ml = weight * ripeness.factor * size.juice_factor * efficiency_factor
        ValueObjects::JuiceVolume.new(juice_ml)
      end

      def potential_waste(efficiency_factor = 0.9)
        # Calculate juice volume first
        juice = potential_juice_volume(efficiency_factor)
        
        # Convert juice volume to weight using density
        # NOTE: This assumes juice density ≈ 1.0 g/ml (water-like)
        # Actual citrus juice density is ~1.04-1.05 g/ml
        # For simulation purposes, this approximation is acceptable
        juice_weight = juice.milliliters * JUICE_DENSITY
        
        # Waste = original fruit weight - juice weight (both in grams)
        (weight - juice_weight).round(2)
      end

      def ==(other)
        other.is_a?(Fruit) && id == other.id
      end
    end
  end
end