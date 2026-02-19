# spec/domain/entities/press_unit_spec.rb
require 'spec_helper'
require 'domain/entities/press_unit'
require 'domain/entities/fruit'

RSpec.describe Domain::Entities::PressUnit do
  describe '#initialize' do
    it 'starts in idle state' do
      press = described_class.new
      expect(press.state).to eq(:idle)
      expect(press.idle?).to be true
    end

    it 'has zero press count' do
      press = described_class.new
      expect(press.press_count).to eq(0)
    end

    # ✅ NEW: Wear and Tear Tests
    it 'starts with 0% wear' do
      press = described_class.new
      expect(press.wear_percentage).to eq(0.0)
    end

    it 'starts with 100% efficiency' do
      press = described_class.new
      expect(press.efficiency_percentage).to eq(100.0)
    end
  end

  describe '#press' do
    it 'presses fruit and returns juice and waste' do
      press = described_class.new
      fruit = Domain::Entities::Fruit.new(type: :orange, size: :medium, ripeness: :ripe, weight: 150)
      
      result = press.press(fruit)
      
      expect(result[:juice]).to be_a(Domain::ValueObjects::JuiceVolume)
      expect(result[:waste]).to be_a(Numeric)
      expect(press.press_count).to eq(1)
    end

    it 'changes state to pressing during operation' do
      press = described_class.new
      fruit = Domain::Entities::Fruit.new(type: :orange, size: :medium, ripeness: :ripe, weight: 150)
      
      # State should return to idle after press
      press.press(fruit)
      expect(press.state).to eq(:idle)
    end

    it 'raises error if not idle' do
      press = described_class.new
      fruit = Domain::Entities::Fruit.new(type: :orange, size: :medium, ripeness: :ripe, weight: 150)
      
      # Manually set to pressing to test
      press.instance_variable_set(:@state, :pressing)
      
      expect { press.press(fruit) }.to raise_error('Press unit not idle')
    end

    it 'resets state to idle even if exception occurs during press' do
      press = described_class.new
      
      # Create a fruit that will raise an exception
      bad_fruit = double('fruit')
      allow(bad_fruit).to receive(:potential_juice_volume).and_raise(StandardError.new('Calculation failed'))
      allow(bad_fruit).to receive(:potential_waste).and_raise(StandardError.new('Calculation failed'))
      
      # Press should raise the exception
      expect { press.press(bad_fruit) }.to raise_error(StandardError, 'Calculation failed')
      
      # But state should be reset to idle (not stuck at :pressing or :error)
      expect(press.idle?).to be true
      expect(press.pressing?).to be false
      expect(press.error?).to be false  # ✅ ADDED: Verify not in error state
      expect(press.press_count).to eq(0)  # ✅ ADDED: Count should NOT increment on failure
    end

    it 'increments press count only on successful press' do
      press = described_class.new
      fruit = Domain::Entities::Fruit.new(type: :orange, size: :medium, ripeness: :ripe, weight: 150)
      
      # Successful press
      press.press(fruit)
      expect(press.press_count).to eq(1)
      
      # Failed press should not increment count
      bad_fruit = double('fruit')
      allow(bad_fruit).to receive(:potential_juice_volume).and_raise(StandardError.new('Failed'))
      allow(bad_fruit).to receive(:potential_waste).and_raise(StandardError.new('Failed'))
      
      expect { press.press(bad_fruit) }.to raise_error(StandardError)
      expect(press.press_count).to eq(1) # Still 1, not 2
    end

    # ✅ NEW: Wear and Tear Tests
    it 'increases wear level with each press' do
      press = described_class.new
      fruit = Domain::Entities::Fruit.new(type: :orange, size: :medium, ripeness: :ripe, weight: 150)
      
      press.press(fruit)
      
      expect(press.wear_percentage).to be > 0
    end

    it 'decreases efficiency as wear increases' do
      press = described_class.new
      fruit = Domain::Entities::Fruit.new(type: :orange, size: :medium, ripeness: :ripe, weight: 150)
      
      # ✅ CHANGED: Actually press fruit to calculate efficiency
      500.times { press.press(fruit) }  # 500 presses = 50% wear
      
      expect(press.efficiency_percentage).to be_within(1.0).of(50.0)
    end

    it 'has minimum 50% efficiency even at 100% wear' do
      press = described_class.new
      fruit = Domain::Entities::Fruit.new(type: :orange, size: :medium, ripeness: :ripe, weight: 150)
      
      # ✅ CHANGED: Actually press fruit to calculate efficiency
      1000.times { press.press(fruit) }  # 1000 presses = 100% wear
      
      expect(press.efficiency_percentage).to eq(50.0)
    end

    it 'applies efficiency to juice output' do
      press = described_class.new
      press.instance_variable_set(:@wear_level, 50)  # 50% efficiency
      fruit = Domain::Entities::Fruit.new(type: :orange, size: :medium, ripeness: :ripe, weight: 150)
      
      result = press.press(fruit)
      
      # Juice should be reduced by efficiency factor
      expect(result[:juice].milliliters).to be < 60  # Less than full efficiency
    end

    it 'raises error when maintenance is required' do
      press = described_class.new
      press.instance_variable_set(:@press_count, 1000)
      fruit = Domain::Entities::Fruit.new(type: :orange, size: :medium, ripeness: :ripe, weight: 150)
      
      expect { press.press(fruit) }.to raise_error('Press unit needs maintenance')
    end
  end

  describe '#trigger_error' do
    it 'sets state to error' do
      press = described_class.new
      press.trigger_error
      expect(press.error?).to be true
    end
  end

  describe '#reset' do
    it 'resets state to idle' do
      press = described_class.new
      press.trigger_error
      press.reset
      expect(press.idle?).to be true
    end
  end

  # ✅ NEW: Maintenance Tests
  describe '#needs_maintenance?' do
    it 'returns false when new' do
      press = described_class.new
      expect(press.needs_maintenance?).to be false
    end

    it 'returns true when press count exceeds max' do
      press = described_class.new
      press.instance_variable_set(:@press_count, 1000)
      
      expect(press.needs_maintenance?).to be true
    end

    it 'returns true when wear reaches 100%' do
      press = described_class.new
      press.instance_variable_set(:@wear_level, 100)
      
      expect(press.needs_maintenance?).to be true
    end
  end

  describe '#perform_maintenance' do
    it 'resets wear to 0%' do
      press = described_class.new
      press.instance_variable_set(:@wear_level, 50)
      press.perform_maintenance
      
      expect(press.wear_percentage).to eq(0.0)
    end

    it 'resets efficiency to 100%' do
      press = described_class.new
      press.instance_variable_set(:@wear_level, 50)
      press.perform_maintenance
      
      expect(press.efficiency_percentage).to eq(100.0)
    end

    it 'resets press count to 0' do
      press = described_class.new
      press.instance_variable_set(:@press_count, 500)
      press.perform_maintenance
      
      expect(press.press_count).to eq(0)
    end

    it 'resets state to idle' do
      press = described_class.new
      press.instance_variable_set(:@state, :error)
      press.perform_maintenance
      
      expect(press.idle?).to be true
    end
  end

  describe '#maintenance_required?' do
    it 'returns false when press count is below max' do
      press = described_class.new
      expect(press.maintenance_required?).to be false
    end

    it 'returns true when press count reaches max' do
      press = described_class.new
      press.instance_variable_set(:@press_count, 1000)
      
      expect(press.maintenance_required?).to be true
    end
  end
end