require 'spec_helper'
require 'domain/juicer_machine'
require 'application/use_cases/get_metrics'

RSpec.describe Application::UseCases::GetMetrics do
  let(:machine) { Domain::JuicerMachine.new }
  let(:use_case) { described_class.new(machine) }

  describe '#execute' do
    it 'returns complete metrics on success' do
      result = use_case.execute
      expect(result[:success]).to be true
      expect(result[:metrics]).to include(:fruits_processed, :total_juice_ml, :total_waste_grams)
      expect(result[:efficiency]).to be_a(Float)
    end

    it 'returns zero efficiency when no fruits processed' do
      result = use_case.execute
      expect(result[:efficiency]).to eq(0.0)
    end

    it 'calculates efficiency with float precision' do
      machine.start
      3.times do
        fruit = Domain::Entities::Fruit.new(type: :orange, size: :medium, ripeness: :ripe, weight: 150)
        machine.feed_fruit(fruit)
      end
      result = use_case.execute
      expect(result[:efficiency]).to be_a(Float)
      expect(result[:efficiency]).to be_within(1.0).of(108.0)
    end

    it 'includes all status components in response' do
      machine.start
      fruit = Domain::Entities::Fruit.new(type: :orange, size: :medium, ripeness: :ripe, weight: 150)
      machine.feed_fruit(fruit)
      result = use_case.execute
      expect(result[:state]).to eq(:running)
      expect(result[:juice_tank]).to be_a(Hash)
    end

    it 'includes metrics on failure for consistent shape' do
      allow(machine).to receive(:status).and_raise(StandardError.new('Test'))
      result = use_case.execute
      expect(result[:success]).to be false
      expect(result[:metrics]).to be_a(Hash)
    end

    it 'returns failure hash on error' do
      allow(machine).to receive(:status).and_raise(StandardError.new('Test'))
      result = use_case.execute
      expect(result[:success]).to be false
      expect(result[:message]).to include('Failed to get metrics')
    end
  end

  describe '#calculate_efficiency' do
    it 'returns 0.0 when no fruits processed' do
      metrics = { fruits_processed: 0, total_juice_ml: 0 }
      efficiency = use_case.send(:calculate_efficiency, metrics)
      expect(efficiency).to eq(0.0)
    end

    it 'calculates correct efficiency for average yield' do
      metrics = { fruits_processed: 3, total_juice_ml: 150.0 }
      efficiency = use_case.send(:calculate_efficiency, metrics)
      expect(efficiency).to eq(100.0)
    end

    it 'calculates efficiency above 100% for high yield' do
      metrics = { fruits_processed: 3, total_juice_ml: 162.0 }
      efficiency = use_case.send(:calculate_efficiency, metrics)
      expect(efficiency).to eq(108.0)
    end

    it 'uses float division not integer division' do
      metrics = { fruits_processed: 3, total_juice_ml: 100.0 }
      efficiency = use_case.send(:calculate_efficiency, metrics)
      expect(efficiency).to be_within(0.01).of(66.67)
    end
  end
end
