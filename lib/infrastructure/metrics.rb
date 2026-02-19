# lib/infrastructure/metrics.rb
require 'prometheus/client'
require 'prometheus/client/formats/text'

module Infrastructure
  class Metrics
    def self.registry
      @registry ||= Prometheus::Client::Registry.new
    end

    def self.setup_metrics
      return if @metrics_setup
      
      registry.counter(
        :juicer_fruits_processed_total,
        docstring: 'Total number of fruits processed',
        labels: [:fruit_type]
      )
      
      registry.counter(
        :juicer_juice_produced_ml_total,
        docstring: 'Total juice produced in milliliters',
        labels: [:fruit_type]
      )
      
      registry.counter(
        :juicer_waste_produced_grams_total,
        docstring: 'Total waste produced in grams',
        labels: [:fruit_type]
      )
      
      registry.counter(
        :juicer_errors_total,
        docstring: 'Total number of errors encountered',
        labels: [:error_type]
      )
      
      registry.counter(
        :juicer_cleaning_cycles_total,
        docstring: 'Total number of cleaning cycles completed'
      )
      
      registry.gauge(
        :juicer_machine_state,
        docstring: 'Current machine state',
        labels: [:state]
      )
      
      registry.gauge(
        :juicer_juice_tank_percentage,
        docstring: 'Current juice tank fill percentage'
      )
      
      registry.gauge(
        :juicer_waste_bin_percentage,
        docstring: 'Current waste bin fill percentage'
      )
      
      registry.histogram(
        :juicer_request_duration_seconds,
        docstring: 'HTTP request duration in seconds',
        buckets: [0.01, 0.05, 0.1, 0.25, 0.5, 1.0]
      )
      
      @metrics_setup = true
    end

    def self.fruits_processed(fruit_type: 'unknown')
      setup_metrics
      registry.get(:juicer_fruits_processed_total).increment(labels: { fruit_type: fruit_type.to_s })
    end

    def self.juice_produced(amount_ml, fruit_type: 'unknown')
      setup_metrics
      registry.get(:juicer_juice_produced_ml_total).increment(
        by: amount_ml,
        labels: { fruit_type: fruit_type.to_s }
      )
    end

    def self.waste_produced(amount_grams, fruit_type: 'unknown')
      setup_metrics
      registry.get(:juicer_waste_produced_grams_total).increment(
        by: amount_grams,
        labels: { fruit_type: fruit_type.to_s }
      )
    end

    def self.error_occurred(error_type: 'unknown')
      setup_metrics
      registry.get(:juicer_errors_total).increment(labels: { error_type: error_type.to_s })
    end

    def self.cleaning_cycle_completed
      setup_metrics
      registry.get(:juicer_cleaning_cycles_total).increment
    end

    def self.set_machine_state(state)
      setup_metrics
      [:idle, :running, :stopped, :error].each do |s|
        begin
          registry.get(:juicer_machine_state).set(0, labels: { state: s.to_s })
        rescue
          # Ignore if metric doesn't exist yet
        end
      end
      begin
        registry.get(:juicer_machine_state).set(1, labels: { state: state.to_s })
      rescue
        # Ignore if metric doesn't exist yet
      end
    end

    def self.set_juice_tank_percentage(percentage)
      setup_metrics
      begin
        registry.get(:juicer_juice_tank_percentage).set(percentage.to_f)
      rescue
        # Ignore errors
      end
    end

    def self.set_waste_bin_percentage(percentage)
      setup_metrics
      begin
        registry.get(:juicer_waste_bin_percentage).set(percentage.to_f)
      rescue
        # Ignore errors
      end
    end

    def self.observe_request_duration(duration_seconds)
      setup_metrics
      registry.get(:juicer_request_duration_seconds).observe(duration_seconds)
    end

    def self.export
      setup_metrics
      Prometheus::Client::Formats::Text.marshal(registry)
    end

    def self.reset!
      @registry = Prometheus::Client::Registry.new
      @metrics_setup = nil
    end
  end
end