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
    
    # But state should be reset to idle (not stuck at :pressing)
    expect(press.idle?).to be true
    expect(press.pressing?).to be false
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
end