require 'spec_helper'
require 'domain/value_objects/fruit_type'

RSpec.describe Domain::ValueObjects::FruitType do
  describe '#initialize' do
    it 'creates orange with correct properties' do
      fruit_type = described_class.new(:orange)
      
      expect(fruit_type.type).to eq(:orange)
      expect(fruit_type.juice_factor).to eq(0.50)
      expect(fruit_type.density).to eq(1.04)
      expect(fruit_type.peel_ratio).to eq(0.30)
      expect(fruit_type.name).to eq('Orange')
    end

    it 'creates lemon with correct properties' do
      fruit_type = described_class.new(:lemon)
      
      expect(fruit_type.juice_factor).to eq(0.40)
      expect(fruit_type.density).to eq(1.03)
      expect(fruit_type.peel_ratio).to eq(0.35)
    end

    it 'creates grapefruit with correct properties' do
      fruit_type = described_class.new(:grapefruit)
      
      expect(fruit_type.juice_factor).to eq(0.45)
      expect(fruit_type.density).to eq(1.05)
      expect(fruit_type.peel_ratio).to eq(0.40)
    end

    it 'raises error for invalid fruit type' do
      expect { described_class.new(:apple) }
        .to raise_error(ArgumentError, /Unknown fruit type/)
    end

    it 'accepts string input and converts to symbol' do
      fruit_type = described_class.new('orange')
      expect(fruit_type.type).to eq(:orange)
    end
  end

  describe '#==' do
    it 'compares equal types correctly' do
      orange1 = described_class.new(:orange)
      orange2 = described_class.new(:orange)
      
      expect(orange1).to eq(orange2)
    end

    it 'compares different types correctly' do
      orange = described_class.new(:orange)
      lemon = described_class.new(:lemon)
      
      expect(orange).not_to eq(lemon)
    end
  end

  describe '.valid?' do
    it 'returns true for valid types' do
      expect(described_class.valid?(:orange)).to be true
      expect(described_class.valid?('lemon')).to be true
    end

    it 'returns false for invalid types' do
      expect(described_class.valid?(:apple)).to be false
    end
  end

  describe '.valid_types' do
    it 'returns array of valid type symbols' do
      types = described_class.valid_types
      
      expect(types).to include(:orange, :lemon, :grapefruit)
      expect(types).not_to include(:apple)
    end
  end

  describe '.default' do
    it 'returns orange as default' do
      default = described_class.default
      
      expect(default.type).to eq(:orange)
    end
  end

  describe '#to_s' do
    it 'returns human-readable name' do
      expect(described_class.new(:orange).to_s).to eq('Orange')
      expect(described_class.new(:lemon).to_s).to eq('Lemon')
    end
  end
end