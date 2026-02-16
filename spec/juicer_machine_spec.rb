require 'spec_helper'
require 'domain/juicer_machine'

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
end