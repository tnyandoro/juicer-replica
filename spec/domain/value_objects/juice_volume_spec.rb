require 'spec_helper'
require 'domain/value_objects/juice_volume'

RSpec.describe Domain::ValueObjects::JuiceVolume do
  describe '#initialize' do
    it 'creates volume with positive value' do
      volume = described_class.new(100)
      expect(volume.milliliters).to eq(100)
    end

    it 'rounds to 2 decimal places' do
      volume = described_class.new(100.12345)
      expect(volume.milliliters).to eq(100.12)
    end

    it 'raises error for negative value' do
      expect { described_class.new(-10) }.to raise_error(ArgumentError)
    end
  end

  describe '#+' do
    it 'adds two volumes' do
      v1 = described_class.new(100)
      v2 = described_class.new(50)
      result = v1 + v2
      expect(result.milliliters).to eq(150)
    end
  end

  describe '#-' do
    it 'subtracts two volumes' do
      v1 = described_class.new(100)
      v2 = described_class.new(30)
      result = v1 - v2
      expect(result.milliliters).to eq(70)
    end

    it 'does not go below zero' do
      v1 = described_class.new(50)
      v2 = described_class.new(100)
      result = v1 - v2
      expect(result.milliliters).to eq(0)
    end
  end

  describe '#*' do
    it 'multiplies volume by factor' do
      v1 = described_class.new(100)
      result = v1 * 0.5
      expect(result.milliliters).to eq(50)
    end
  end

  describe '#zero?' do
    it 'returns true for zero volume' do
      v = described_class.new(0)
      expect(v.zero?).to be true
    end

    it 'returns false for non-zero volume' do
      v = described_class.new(10)
      expect(v.zero?).to be false
    end
  end

  describe '#to_s' do
    it 'returns formatted string' do
      v = described_class.new(150)
      expect(v.to_s).to eq('150 ml')
    end
  end
end