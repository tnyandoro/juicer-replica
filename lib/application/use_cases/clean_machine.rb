require_relative '../../domain/juicer_machine'

module Application
  module UseCases
    class CleanMachine
      def initialize(machine)
        @machine = machine
      end

      def execute
        @machine.clean
        
        {
          success: true,
          message: "Machine cleaned successfully",
          state: @machine.state,
          cleaning_cycles: @machine.metrics[:cleaning_cycles]
        }
      rescue => e
        {
          success: false,
          message: "Failed to clean machine: #{e.message}",
          state: @machine.state
        }
      end
    end
  end
end
