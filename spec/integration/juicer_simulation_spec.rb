require 'spec_helper'
require 'domain/juicer_machine'

RSpec.describe 'Juicer Simulation' do
  let(:machine) { Domain::JuicerMachine.new }

  describe 'Complete juicing workflow' do
    it 'processes multiple fruits and tracks all metrics' do
      # Start machine
      machine.start
      expect(machine.running?).to be true

      # Feed 5 fruits
      5.times do |i|
        fruit = Domain::Entities::Fruit.new(
          type: :orange,
          size: :medium,
          ripeness: :ripe,
          weight: 150 + (i * 10)
        )
        machine.feed_fruit(fruit)
      end

      # Verify metrics
      expect(machine.metrics[:fruits_processed]).to eq(5)
      expect(machine.metrics[:total_juice_ml]).to be > 0
      expect(machine.metrics[:total_waste_grams]).to be > 0

      # Check status
      status = machine.status
      expect(status[:juice_tank][:percentage]).to be > 0
      expect(status[:waste_bin][:percentage]).to be > 0

      # Stop machine
      machine.stop
      expect(machine.stopped?).to be true

      # Clean machine
      machine.clean
      expect(machine.idle?).to be true
      expect(machine.metrics[:cleaning_cycles]).to eq(1)
    end
  end

  describe 'Tank overflow protection' do
    it 'prevents adding juice when tank is full' do
      machine.start
      
      # Create small tank for testing (100ml capacity)
      # Each large orange produces ~58ml juice, so 2nd fruit will overflow
      small_tank = Domain::Entities::JuiceTank.new(capacity_ml: 100)
      machine.instance_variable_set(:@juice_tank, small_tank)
      
      # Use large fruit that produces ~58ml juice
      fruit = Domain::Entities::Fruit.new(
        type: :orange,
        size: :large,
        ripeness: :ripe,
        weight: 250
      )
      
      # First fruit should work (fills tank to ~58%)
      machine.feed_fruit(fruit)
      
      # Second fruit should overflow (would exceed 100ml capacity)
      expect { machine.feed_fruit(fruit) }.to raise_error(ArgumentError, /Tank would overflow/)
    end
  end

  describe 'Error handling and recovery' do
    it 'recovers from press unit error after reset' do
      machine.start
      
      # Trigger error
      machine.instance_variable_get(:@press_unit).trigger_error
      
      # Reset machine
      machine.reset_to_idle
      
      # Should be able to start again
      machine.start
      expect(machine.running?).to be true
    end

    it 'recovers from filter clog after cleaning' do
      machine.start
      
      # Clog filter
      filter = machine.instance_variable_get(:@filter_unit)
      filter.instance_variable_set(:@clog_level, 100)
      filter.check_clog!
      
      # Clean machine
      machine.clean
      
      # Filter should be reset
      expect(filter.clogged?).to be false
    end
  end
end