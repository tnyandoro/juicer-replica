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
      # weight: 150g, ripeness: 0.8, size_factor: 0.5, fruit_type: 0.5, density: 1.04
      # 150 * 0.5 * 0.8 * 0.5 / 1.04 = 28.85 ml
      fruit = described_class.new(type: :orange, size: :medium, ripeness: :ripe, weight: 150)
      juice = fruit.potential_juice_volume  # ✅ NO argument
      expect(juice.milliliters).to be_within(1.0).of(28.85)  # ✅ FIXED from 57.69
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
    it 'calculates waste based on fruit type peel ratio' do
      fruit = described_class.new(type: :orange, size: :medium, ripeness: :ripe, weight: 150)
      waste = fruit.potential_waste  # ✅ NO argument
      
      # Orange peel_ratio is 0.30, so peel = 45g, other waste = 10.5g, total = 55.5g
      expect(waste).to be_within(1.0).of(55.5)
    end

    it 'uses fruit-specific density from FruitType' do
      orange = Domain::Entities::Fruit.new(type: :orange, weight: 150)
      lemon = Domain::Entities::Fruit.new(type: :lemon, weight: 150)
      
      expect(orange.fruit_type.density).to eq(1.04)
      expect(lemon.fruit_type.density).to eq(1.03)
      expect(orange.fruit_type.density).not_to eq(lemon.fruit_type.density)
    end

    it 'calculates waste with consistent units (grams)' do
      fruit = described_class.new(type: :orange, size: :medium, ripeness: :ripe, weight: 150)
      waste = fruit.potential_waste  # ✅ NO argument
      
      # Waste should be in grams
      expect(waste).to be > 0
      expect(waste).to be < fruit.weight
    end
  end

  describe 'Variable efficiency by fruit type' do
    it 'calculates different juice volumes for different fruit types' do
      orange = Domain::Entities::Fruit.new(type: :orange, size: :medium, ripeness: :ripe, weight: 150)
      lemon = Domain::Entities::Fruit.new(type: :lemon, size: :medium, ripeness: :ripe, weight: 150)
      grapefruit = Domain::Entities::Fruit.new(type: :grapefruit, size: :medium, ripeness: :ripe, weight: 150)
      
      orange_juice = orange.potential_juice_volume.milliliters
      lemon_juice = lemon.potential_juice_volume.milliliters
      grapefruit_juice = grapefruit.potential_juice_volume.milliliters
      
      expect(orange_juice).to be > lemon_juice
      expect(grapefruit_juice).to be > lemon_juice
      expect(grapefruit_juice).to be < orange_juice
    end

    it 'calculates different waste amounts for different fruit types' do
      orange = Domain::Entities::Fruit.new(type: :orange, weight: 150)
      lemon = Domain::Entities::Fruit.new(type: :lemon, weight: 150)
      grapefruit = Domain::Entities::Fruit.new(type: :grapefruit, weight: 150)
      
      expect(grapefruit.potential_waste).to be > orange.potential_waste
      expect(lemon.potential_waste).to be > orange.potential_waste
    end

    it 'uses fruit-specific density for ml conversion' do
      orange = Domain::Entities::Fruit.new(type: :orange, weight: 150)
      grapefruit = Domain::Entities::Fruit.new(type: :grapefruit, weight: 150)
      
      orange_juice = orange.potential_juice_volume.milliliters
      grapefruit_juice = grapefruit.potential_juice_volume.milliliters
      
      expect((orange_juice - grapefruit_juice).abs).to be_within(1.0).of(3.0)
    end

    it 'maintains backward compatibility with symbol-based initialization' do
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