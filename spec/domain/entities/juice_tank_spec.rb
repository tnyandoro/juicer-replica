require 'spec_helper'
require 'domain/entities/juice_tank'

RSpec.describe Domain::Entities::JuiceTank do
  describe '#initialize' do
    it 'creates tank with default capacity' do
      tank = described_class.new
      expect(tank.capacity.milliliters).to eq(5000)
      expect(tank.current_volume.milliliters).to eq(0)
    end

    it 'creates tank with custom capacity' do
      tank = described_class.new(capacity_ml: 3000)
      expect(tank.capacity.milliliters).to eq(3000)
    end
  end

  describe '#add_juice' do
    it 'adds juice to tank' do
      tank = described_class.new
      volume = Domain::ValueObjects::JuiceVolume.new(100)
      tank.add_juice(volume)
      expect(tank.current_volume.milliliters).to eq(100)
    end

    it 'tracks juice count' do
      tank = described_class.new
      tank.add_juice(Domain::ValueObjects::JuiceVolume.new(100))
      tank.add_juice(Domain::ValueObjects::JuiceVolume.new(50))
      expect(tank.juice_count).to eq(2)
    end

    it 'raises error when tank would overflow' do
      tank = described_class.new(capacity_ml: 100)
      tank.add_juice(Domain::ValueObjects::JuiceVolume.new(80))
      
      expect { tank.add_juice(Domain::ValueObjects::JuiceVolume.new(30)) }
        .to raise_error(ArgumentError, 'Tank would overflow')
    end
  end

  describe '#empty!' do
    it 'empties the tank' do
      tank = described_class.new
      tank.add_juice(Domain::ValueObjects::JuiceVolume.new(100))
      tank.empty!
      expect(tank.current_volume.milliliters).to eq(0)
    end
  end

  describe '#full?' do
    it 'returns true when tank is full' do
      tank = described_class.new(capacity_ml: 100)
      tank.add_juice(Domain::ValueObjects::JuiceVolume.new(100))
      expect(tank.full?).to be true
    end

    it 'returns false when tank is not full' do
      tank = described_class.new(capacity_ml: 100)
      tank.add_juice(Domain::ValueObjects::JuiceVolume.new(50))
      expect(tank.full?).to be false
    end
  end

  describe '#percentage_full' do
    it 'calculates percentage correctly' do
      tank = described_class.new(capacity_ml: 1000)
      tank.add_juice(Domain::ValueObjects::JuiceVolume.new(500))
      expect(tank.percentage_full).to eq(50.0)
    end
  end
end