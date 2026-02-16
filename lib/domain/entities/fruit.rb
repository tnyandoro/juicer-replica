require 'securerandom'
require_relative '../value_objects/fruit_size'
require_relative '../value_objects/ripeness_level'

module Domain
  module Entities
    class Fruit
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
        juice_ml = weight * ripeness.factor * size.juice_factor * efficiency_factor
        ValueObjects::JuiceVolume.new(juice_ml)
      end

      def potential_waste(efficiency_factor = 0.9)
        juice = potential_juice_volume(efficiency_factor)
        (weight - juice.milliliters).round(2)
      end

      def ==(other)
        other.is_a?(Fruit) && id == other.id
      end
    end
  end
end