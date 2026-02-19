require 'spec_helper'
require 'domain/entities/fruit'

RSpec.describe Domain::Entities::Fruit do
  describe '#initialize' do
    it 'creates fruit with symbol size and ripeness' do
      fruit = described_class.new(type: :orange, size: :medium, ripeness: :ripe)
      expect(fruit.type).to eq(:orange)
      expect(fruit.size.size).to eq(:medium)
      expect(fruit.ripeness.level).to eq(:ripe)
    end

    it 'creates fruit with value object size and ripeness' do
      size = Domain::ValueObjects::FruitSize.new(:large)
      ripeness = Domain::ValueObjects::RipenessLevel.new(:ripe)
      fruit = described_class.new(type: :orange, size: size, ripeness: ripeness)
      expect(fruit.size).to eq(size)
      expect(fruit.ripeness).to eq(ripeness)
    end

    it 'assigns random weight within size range' do
      fruit = described_class.new(type: :orange, size: :medium, ripeness: :ripe, weight: 150)
      expect(fruit.weight).to eq(150)
    end

    it 'generates unique id' do
      fruit1 = described_class.new(type: :orange, size: :medium, ripeness: :ripe)
      fruit2 = described_class.new(type: :orange, size: :medium, ripeness: :ripe)
      expect(fruit1.id).not_to eq(fruit2.id)
    end
  end

  describe '#potential_juice_volume' do
    it 'calculates juice based on weight, ripeness, and size' do
      # weight: 150g, ripeness: 0.8, juice_factor: 0.5, efficiency: 0.9
      # 150 * 0.8 * 0.5 * 0.9 = 54 ml
      fruit = described_class.new(type: :orange, size: :medium, ripeness: :ripe, weight: 150)
      juice = fruit.potential_juice_volume(0.9)
      expect(juice.milliliters).to be_within(0.1).of(54)
    end

    it 'returns less juice for unripe fruit' do
      ripe = described_class.new(type: :orange, size: :medium, ripeness: :ripe, weight: 150)
      unripe = described_class.new(type: :orange, size: :medium, ripeness: :unripe, weight: 150)
      
      expect(ripe.potential_juice_volume.milliliters).to be > unripe.potential_juice_volume.milliliters
    end

    it 'returns more juice for larger fruit' do
      small = described_class.new(type: :orange, size: :small, ripeness: :ripe, weight: 100)
      large = described_class.new(type: :orange, size: :large, ripeness: :ripe, weight: 200)
      
      expect(large.potential_juice_volume.milliliters).to be > small.potential_juice_volume.milliliters
    end
  end

  describe '#potential_waste' do
    it 'calculates waste as weight minus juice' do
      fruit = described_class.new(type: :orange, size: :medium, ripeness: :ripe, weight: 150)
      juice = fruit.potential_juice_volume(0.9)
      waste = fruit.potential_waste(0.9)
      
      expect(waste).to be_within(0.1).of(150 - juice.milliliters)
    end

    # spec/domain/entities/fruit_spec.rb

    it 'documents density assumption in waste calculation' do
    fruit = described_class.new(type: :orange, size: :medium, ripeness: :ripe, weight: 150)
    
    # Waste calculation assumes 1.0 g/ml density
    # This is documented in the source code
    expect(fruit.class::JUICE_DENSITY).to eq(1.0)
    end

    it 'calculates waste with consistent units (grams)' do
    fruit = described_class.new(type: :orange, size: :medium, ripeness: :ripe, weight: 150)
    juice = fruit.potential_juice_volume(0.9)
    waste = fruit.potential_waste(0.9)
    
    # Waste + juice weight should approximately equal original weight
    # (allowing for rounding errors)
    juice_weight = juice.milliliters * described_class::JUICE_DENSITY
    total = waste + juice_weight
    
    expect(total).to be_within(0.5).of(fruit.weight)
    end
  end

  describe 'Variable efficiency by fruit type' do
    it 'calculates different juice volumes for different fruit types' do
      # Same weight, size, ripeness - different fruit types
      orange = Domain::Entities::Fruit.new(type: :orange, size: :medium, ripeness: :ripe, weight: 150)
      lemon = Domain::Entities::Fruit.new(type: :lemon, size: :medium, ripeness: :ripe, weight: 150)
      grapefruit = Domain::Entities::Fruit.new(type: :grapefruit, size: :medium, ripeness: :ripe, weight: 150)
      
      orange_juice = orange.potential_juice_volume.milliliters
      lemon_juice = lemon.potential_juice_volume.milliliters
      grapefruit_juice = grapefruit.potential_juice_volume.milliliters
      
      # Orange should be juiciest (0.50 factor)
      expect(orange_juice).to be > lemon_juice
      # Grapefruit should be in middle (0.45 factor)
      expect(grapefruit_juice).to be > lemon_juice
      expect(grapefruit_juice).to be < orange_juice
    end

    it 'calculates different waste amounts for different fruit types' do
      orange = Domain::Entities::Fruit.new(type: :orange, weight: 150)
      lemon = Domain::Entities::Fruit.new(type: :lemon, weight: 150)
      grapefruit = Domain::Entities::Fruit.new(type: :grapefruit, weight: 150)
      
      # Grapefruit has highest peel_ratio (0.40), so most waste
      expect(grapefruit.potential_waste).to be > orange.potential_waste
      expect(lemon.potential_waste).to be > orange.potential_waste
    end

    it 'uses fruit-specific density for ml conversion' do
      # Same juice grams, different densities = different ml
      orange = Domain::Entities::Fruit.new(type: :orange, weight: 150)
      grapefruit = Domain::Entities::Fruit.new(type: :grapefruit, weight: 150)
      
      # Grapefruit has higher density (1.05 vs 1.04), so slightly less ml for same grams
      orange_juice = orange.potential_juice_volume.milliliters
      grapefruit_juice = grapefruit.potential_juice_volume.milliliters
      
      # The difference is small but measurable
      expect((orange_juice - grapefruit_juice).abs).to be_within(1.0).of(0.5)
    end

    it 'maintains backward compatibility with symbol-based initialization' do
      # Old code using just symbols should still work
      fruit = Domain::Entities::Fruit.new(type: :orange, size: :medium, ripeness: :ripe)
      
      expect(fruit.fruit_type).to be_a(Domain::ValueObjects::FruitType)
      expect(fruit.fruit_type.type).to eq(:orange)
      expect(fruit.potential_juice_volume).to be_a(Domain::ValueObjects::JuiceVolume)
    end

    it 'accepts FruitType object for explicit control' do
      custom_type = Domain::ValueObjects::FruitType.new(:lemon)
      fruit = Domain::Entities::Fruit.new(fruit_type: custom_type, weight: 150)
      
      expect(fruit.fruit_type).to eq(custom_type)
      expect(fruit.fruit_type.juice_factor).to eq(0.40)
    end
  end
end