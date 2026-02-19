require 'securerandom'
require_relative '../value_objects/fruit_size'
require_relative '../value_objects/ripeness_level'
require_relative '../value_objects/fruit_type'
require_relative '../value_objects/juice_volume'

module Domain
  module Entities
    class Fruit
      attr_reader :id, :type, :size, :ripeness, :weight, :fruit_type

      def initialize(type: :orange, size: :medium, ripeness: :ripe, weight: nil, fruit_type: nil)
        @id = SecureRandom.uuid
        @type = type.to_sym
        
        if fruit_type.is_a?(ValueObjects::FruitType)
          @fruit_type = fruit_type
        else
          @fruit_type = ValueObjects::FruitType.new(@type)
        end
        
        @size = size.is_a?(ValueObjects::FruitSize) ? size : ValueObjects::FruitSize.new(size)
        @ripeness = ripeness.is_a?(ValueObjects::RipenessLevel) ? ripeness : ValueObjects::RipenessLevel.new(ripeness)
        @weight = weight || default_weight_for_size
      end

      # ✅ LINE 28 - NO PARAMETERS (this is the critical fix)
      def potential_juice_volume
        juice_grams = @weight * @size.juice_factor * @ripeness.factor * @fruit_type.juice_factor
        juice_ml = juice_grams / @fruit_type.density
        ValueObjects::JuiceVolume.new(juice_ml)
      end

      def potential_waste
        peel_grams = @weight * @fruit_type.peel_ratio
        other_waste_grams = (@weight - peel_grams) * 0.1
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