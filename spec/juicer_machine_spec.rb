require 'spec_helper'
require 'domain/juicer_machine'
require 'domain/entities/fruit'
require 'domain/entities/juice_tank'
require 'domain/entities/waste_bin'

RSpec.describe Domain::JuicerMachine do
  let(:machine) { described_class.new }

  describe '#initialize' do
    it 'starts in idle state' do
      expect(machine.state).to eq(:idle)
      expect(machine.idle?).to be true
    end

    it 'has empty metrics' do
      expect(machine.metrics[:fruits_processed]).to eq(0)
      expect(machine.metrics[:total_juice_ml]).to eq(0)
      expect(machine.metrics[:total_waste_grams]).to eq(0)
      expect(machine.metrics[:errors]).to eq(0)
      expect(machine.metrics[:cleaning_cycles]).to eq(0)
    end
  end

  describe '#start' do
    it 'changes state to running' do
      machine.start
      expect(machine.running?).to be true
    end

    it 'raises error if not idle' do
      machine.start
      expect { machine.start }.to raise_error('Machine not idle')
    end
  end

  describe '#stop' do
    it 'changes state to stopped' do
      machine.start
      machine.stop
      expect(machine.stopped?).to be true
    end

    it 'raises error if not running' do
      expect { machine.stop }.to raise_error('Machine not running')
    end
  end

  describe '#feed_fruit' do
    it 'processes fruit and returns juice and waste' do
      machine.start
      fruit = Domain::Entities::Fruit.new(type: :orange, size: :medium, ripeness: :ripe, weight: 150)
      
      result = machine.feed_fruit(fruit)
      
      expect(result[:juice]).to be_a(Domain::ValueObjects::JuiceVolume)
      expect(result[:waste]).to be_a(Numeric)
    end

    it 'updates metrics' do
      machine.start
      fruit = Domain::Entities::Fruit.new(type: :orange, size: :medium, ripeness: :ripe, weight: 150)
      
      machine.feed_fruit(fruit)
      
      expect(machine.metrics[:fruits_processed]).to eq(1)
      expect(machine.metrics[:total_juice_ml]).to be > 0
      expect(machine.metrics[:total_waste_grams]).to be > 0
    end

    it 'raises error if machine not running' do
      fruit = Domain::Entities::Fruit.new(type: :orange, size: :medium, ripeness: :ripe, weight: 150)
      expect { machine.feed_fruit(fruit) }.to raise_error('Machine not running')
    end

    it 'raises error if press unit has error' do
      machine.start
      machine.instance_variable_get(:@press_unit).trigger_error
      fruit = Domain::Entities::Fruit.new(type: :orange, size: :medium, ripeness: :ripe, weight: 150)
      
      expect { machine.feed_fruit(fruit) }.to raise_error('Press unit error')
    end

    it 'raises error if filter is clogged' do
      machine.start
      filter = machine.instance_variable_get(:@filter_unit)
      filter.instance_variable_set(:@state, :clogged)
      fruit = Domain::Entities::Fruit.new(type: :orange, size: :medium, ripeness: :ripe, weight: 150)
      
      expect { machine.feed_fruit(fruit) }.to raise_error('Filter clogged')
    end

    # ✅ State Consistency Tests (CodeRabbit Fix)
    it 'pre-validates tank capacity before mutating state' do
      machine.start
      
      # Create a tank with very small capacity
      small_tank = Domain::Entities::JuiceTank.new(capacity_ml: 10)
      machine.instance_variable_set(:@juice_tank, small_tank)
      
      # Large fruit that would overflow
      large_fruit = Domain::Entities::Fruit.new(
        type: :orange,
        size: :large,
        ripeness: :ripe,
        weight: 250
      )
      
      # Should raise before any state changes
      expect { machine.feed_fruit(large_fruit) }.to raise_error(ArgumentError, /Tank would overflow/)
      
      # Metrics should NOT be updated (state consistency)
      expect(machine.metrics[:fruits_processed]).to eq(0)
      expect(machine.metrics[:total_juice_ml]).to eq(0)
    end

    it 'pre-validates bin capacity before mutating state' do
      machine.start
      
      # Create a bin with very small capacity
      small_bin = Domain::Entities::WasteBin.new(capacity_grams: 10)
      machine.instance_variable_set(:@waste_bin, small_bin)
      
      # Large fruit that would overflow bin
      large_fruit = Domain::Entities::Fruit.new(
        type: :orange,
        size: :large,
        ripeness: :ripe,
        weight: 250
      )
      
      # Should raise before any state changes
      expect { machine.feed_fruit(large_fruit) }.to raise_error(ArgumentError, /Bin would overflow/)
      
      # Metrics should NOT be updated (state consistency)
      expect(machine.metrics[:fruits_processed]).to eq(0)
      expect(machine.metrics[:total_waste_grams]).to eq(0)
    end

    it 'tracks errors when feed_fruit fails' do
      machine.start
      
      small_tank = Domain::Entities::JuiceTank.new(capacity_ml: 10)
      machine.instance_variable_set(:@juice_tank, small_tank)
      
      large_fruit = Domain::Entities::Fruit.new(
        type: :orange,
        size: :large,
        ripeness: :ripe,
        weight: 250
      )
      
      expect { machine.feed_fruit(large_fruit) }.to raise_error
      
      # Error should be tracked in metrics
      expect(machine.metrics[:errors]).to eq(1)
    end

    it 'maintains consistent state after successful feed' do
      machine.start
      
      fruit = Domain::Entities::Fruit.new(
        type: :orange,
        size: :medium,
        ripeness: :ripe,
        weight: 150
      )
      
      result = machine.feed_fruit(fruit)
      
      # All metrics should be updated consistently
      expect(machine.metrics[:fruits_processed]).to eq(1)
      expect(machine.metrics[:total_juice_ml]).to be > 0
      expect(machine.metrics[:total_waste_grams]).to be > 0
      
      # Tank and bin should have matching data
      status = machine.status
      expect(status[:juice_tank][:percentage]).to be > 0
      expect(status[:waste_bin][:percentage]).to be > 0
    end

    it 'uses filtered juice volume not original press result' do
      machine.start
      fruit = Domain::Entities::Fruit.new(type: :orange, size: :medium, ripeness: :ripe, weight: 150)
      
      # Feed fruit through full flow
      machine.feed_fruit(fruit)
      
      # Tank should have filtered juice
      tank_volume = machine.instance_variable_get(:@juice_tank).current_volume.milliliters
      metrics_volume = machine.metrics[:total_juice_ml]
      
      # Tank and metrics should match (both use filtered juice)
      expect(tank_volume).to eq(metrics_volume)
    end
  end

  describe '#clean' do
    it 'empties juice tank' do
      machine.start
      fruit = Domain::Entities::Fruit.new(type: :orange, size: :medium, ripeness: :ripe, weight: 150)
      machine.feed_fruit(fruit)
      
      machine.clean
      
      expect(machine.instance_variable_get(:@juice_tank).current_volume.milliliters).to eq(0)
    end

    it 'empties waste bin' do
      machine.start
      fruit = Domain::Entities::Fruit.new(type: :orange, size: :medium, ripeness: :ripe, weight: 150)
      machine.feed_fruit(fruit)
      
      machine.clean
      
      expect(machine.instance_variable_get(:@waste_bin).current_waste).to eq(0)
    end

    it 'resets filter unit' do
      machine.start
      fruit = Domain::Entities::Fruit.new(type: :orange, size: :medium, ripeness: :ripe, weight: 150)
      machine.feed_fruit(fruit)
      
      machine.clean
      
      filter = machine.instance_variable_get(:@filter_unit)
      expect(filter.clog_level).to eq(0)
    end

    it 'increments cleaning cycles metric' do
      machine.clean
      expect(machine.metrics[:cleaning_cycles]).to eq(1)
    end

    it 'returns machine to idle state' do
      machine.start
      machine.clean
      expect(machine.idle?).to be true
    end
  end

  describe '#status' do
    it 'returns complete status hash' do
      machine.start
      fruit = Domain::Entities::Fruit.new(type: :orange, size: :medium, ripeness: :ripe, weight: 150)
      machine.feed_fruit(fruit)
      
      status = machine.status
      
      expect(status).to include(:state, :juice_tank, :waste_bin, :press_unit, :filter_unit, :metrics)
      expect(status[:state]).to eq(:running)
    end
  end

  describe '#reset_to_idle' do
    it 'resets machine to idle state' do
      machine.start
      machine.reset_to_idle
      expect(machine.idle?).to be true
    end
  end

  describe 'Tank overflow protection' do
    it 'prevents adding juice when tank is full' do
      machine.start
      
      # Create small tank for testing
      small_tank = Domain::Entities::JuiceTank.new(capacity_ml: 100)
      machine.instance_variable_set(:@juice_tank, small_tank)
      
      # Feed fruit until tank is nearly full
      fruit = Domain::Entities::Fruit.new(type: :orange, size: :large, ripeness: :ripe, weight: 200)
      
      # First fruit should work
      machine.feed_fruit(fruit)
      
      # Second fruit should overflow
      expect { machine.feed_fruit(fruit) }.to raise_error(ArgumentError, /Tank would overflow/)
    end
  end
end