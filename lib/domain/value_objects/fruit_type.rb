module Domain
  module ValueObjects
    class FruitType
      # Fruit-specific properties for realistic simulation
      # Based on USDA nutritional data for citrus fruits
      TYPES = {
        orange: {
          juice_factor: 0.50,    # 50% of weight becomes juice
          density: 1.04,          # g/ml (slightly denser than water)
          peel_ratio: 0.30,       # 30% of weight is peel/waste
          name: 'Orange'
        },
        lemon: {
          juice_factor: 0.40,     # Lemons are less juicy
          density: 1.03,
          peel_ratio: 0.35,       # Thicker peel
          name: 'Lemon'
        },
        grapefruit: {
          juice_factor: 0.45,     # Medium juiciness
          density: 1.05,          # Densest of the three
          peel_ratio: 0.40,       # Thick peel and membranes
          name: 'Grapefruit'
        }
      }.freeze

      attr_reader :type, :juice_factor, :density, :peel_ratio, :name

      def initialize(type)
        @type = type.to_sym
        config = TYPES[@type]
        
        raise ArgumentError, "Unknown fruit type: #{type}. Valid types: #{valid_types}" unless config
        
        @juice_factor = config[:juice_factor]
        @density = config[:density]
        @peel_ratio = config[:peel_ratio]
        @name = config[:name]
      end

      def ==(other)
        other.is_a?(FruitType) && type == other.type
      end

      def to_s
        name
      end

      def self.valid?(type)
        TYPES.key?(type.to_sym)
      end

      def self.valid_types
        TYPES.keys
      end

      def self.default
        new(:orange)
      end
    end
  end
end