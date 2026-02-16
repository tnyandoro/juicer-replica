require_relative '../../domain/juicer_machine'

module Application
  module UseCases
    class GetMetrics
      def initialize(machine)
        @machine = machine
      end

      def execute
        status = @machine.status
        
        {
          success: true,
          state: status[:state],
          juice_tank: status[:juice_tank],
          waste_bin: status[:waste_bin],
          press_unit: status[:press_unit],
          filter_unit: status[:filter_unit],
          metrics: status[:metrics],
          efficiency: calculate_efficiency(status[:metrics])
        }
      end

      private

      def calculate_efficiency(metrics)
        return 0.0 if metrics[:fruits_processed] == 0
        juice_per_fruit = metrics[:total_juice_ml] / metrics[:fruits_processed]
        expected_yield = 50.0
        ((juice_per_fruit / expected_yield) * 100).round(2)
      end
    end
  end
end
