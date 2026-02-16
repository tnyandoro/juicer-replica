require 'spec_helper'
require 'domain/entities/waste_bin'

RSpec.describe Domain::Entities::WasteBin do
  describe '#initialize' do
    it 'creates bin with default capacity' do
      bin = described_class.new
      expect(bin.capacity).to eq(2000)
      expect(bin.current_waste).to eq(0)
    end

    it 'creates bin with custom capacity' do
      bin = described_class.new(capacity_grams: 1000)
      expect(bin.capacity).to eq(1000)
    end
  end

  describe '#add_waste' do
    it 'adds waste to bin' do
      bin = described_class.new
      bin.add_waste(100)
      expect(bin.current_waste).to eq(100)
    end

    it 'tracks waste count' do
      bin = described_class.new
      bin.add_waste(100)
      bin.add_waste(50)
      expect(bin.waste_count).to eq(2)
    end

    it 'raises error when bin would overflow' do
      bin = described_class.new(capacity_grams: 100)
      bin.add_waste(80)
      
      expect { bin.add_waste(30) }.to raise_error(ArgumentError, 'Bin would overflow')
    end
  end

  describe '#empty!' do
    it 'empties the bin' do
      bin = described_class.new
      bin.add_waste(100)
      bin.empty!
      expect(bin.current_waste).to eq(0)
    end
  end

  describe '#full?' do
    it 'returns true when bin is full' do
      bin = described_class.new(capacity_grams: 100)
      bin.add_waste(100)
      expect(bin.full?).to be true
    end

    it 'returns false when bin is not full' do
      bin = described_class.new(capacity_grams: 100)
      bin.add_waste(50)
      expect(bin.full?).to be false
    end
  end

  describe '#percentage_full' do
    it 'calculates percentage correctly' do
      bin = described_class.new(capacity_grams: 1000)
      bin.add_waste(500)
      expect(bin.percentage_full).to eq(50.0)
    end
  end
end