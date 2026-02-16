# spec/cli/juicer_cli_spec.rb
require 'spec_helper'
require 'domain/juicer_machine'
require 'application/use_cases/start_juicing'
require 'application/use_cases/stop_juicing'
require 'application/use_cases/clean_machine'
require 'application/use_cases/feed_fruit'
require 'application/use_cases/get_metrics'
require 'application/use_cases/get_status'

RSpec.describe 'Juicer CLI Integration' do
  let(:machine) { Domain::JuicerMachine.new }
  
  describe 'Complete CLI workflow' do
    it 'simulates full juicing session' do
      # Start machine
      start_use_case = Application::UseCases::StartJuicing.new(machine)
      result = start_use_case.execute
      expect(result[:success]).to be true
      expect(machine.running?).to be true
      
      # Feed multiple fruits
      feed_use_case = Application::UseCases::FeedFruit.new(machine)
      3.times do |i|
        result = feed_use_case.execute(
          type: :orange,
          size: :medium,
          ripeness: :ripe,
          weight: 150 + (i * 10)
        )
        expect(result[:success]).to be true
        expect(result[:juice]).to include('ml')
      end
      
      # Check metrics
      metrics_use_case = Application::UseCases::GetMetrics.new(machine)
      result = metrics_use_case.execute
      expect(result[:metrics][:fruits_processed]).to eq(3)
      expect(result[:metrics][:total_juice_ml]).to be > 0
      
      # Stop machine
      stop_use_case = Application::UseCases::StopJuicing.new(machine)
      result = stop_use_case.execute
      expect(result[:success]).to be true
      expect(machine.stopped?).to be true
      
      # Clean machine
      clean_use_case = Application::UseCases::CleanMachine.new(machine)
      result = clean_use_case.execute
      expect(result[:success]).to be true
      expect(machine.idle?).to be true
    end
  end
  
  describe 'Error handling' do
    it 'prevents feeding when machine is not running' do
      feed_use_case = Application::UseCases::FeedFruit.new(machine)
      result = feed_use_case.execute(
        type: :orange,
        size: :medium,
        ripeness: :ripe,
        weight: 150
      )
      
      expect(result[:success]).to be false
      expect(result[:message]).to include('Failed to process')
    end
    
    it 'prevents starting when already running' do
      start_use_case = Application::UseCases::StartJuicing.new(machine)
      start_use_case.execute
      
      result = start_use_case.execute
      expect(result[:success]).to be false
    end
  end
end