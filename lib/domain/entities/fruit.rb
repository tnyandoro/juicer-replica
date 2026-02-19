require 'securerandom'
require_relative '../value_objects/fruit_size'
require_relative '../value_objects/ripeness_level'
require_relative '../value_objects/fruit_type'
require_relative '../value_objects/juice_volume'

module Domain
  module Entities
    class Fruit
      attr_reader :id, :type, :size, :ripeness, :weight, :fruit_type

      # Default values for backward compatibility
      DEFAULT_JUICE_FACTOR = 0.5
      DEFAULT_DENSITY = 1.0
      DEFAULT_PEEL_RATIO = 0.3

      def initialize(type: :orange, size: :medium, ripeness: :ripe, weight: nil, fruit_type: nil)
        @id = SecureRandom.uuid
        @type = type.to_sym
        
        # Support both old symbol-based and new FruitType-based initialization
        if fruit_type.is_a?(ValueObjects::FruitType)
          @fruit_type = fruit_type
        else
          @fruit_type = ValueObjects::FruitType.new(@type)
        end
        
        @size = size.is_a?(ValueObjects::FruitSize) ? size : ValueObjects::FruitSize.new(size)
        @ripeness = ripeness.is_a?(ValueObjects::RipenessLevel) ? ripeness : ValueObjects::RipenessLevel.new(ripeness)
        @weight = weight || default_weight_for_size
      end

      def potential_juice_volume
        # Juice calculation: weight * size_factor * ripeness_factor * fruit_type_factor
        juice_grams = @weight * @size.juice_factor * @ripeness.factor * @fruit_type.juice_factor
        
        # Convert grams to milliliters using fruit-specific density
        juice_ml = juice_grams / @fruit_type.density
        
        ValueObjects::JuiceVolume.new(juice_ml)
      end

      def potential_waste
        # Waste = peel + seeds + pulp not extracted
        # Peel is fruit-type specific, rest is proportional
        peel_grams = @weight * @fruit_type.peel_ratio
        other_waste_grams = (@weight - peel_grams) * 0.1  # 10% additional waste
        
        (peel_grams + other_waste_grams).round(2)
      end

      def default_weight_for_size
        case @size.type
        when :small then rand(80..120)
        when :medium then rand(120..180)
        when :large then rand(180..250)
        else 150
        end
      end
    end
  end
end