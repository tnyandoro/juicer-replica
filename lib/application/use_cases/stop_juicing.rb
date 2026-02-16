require_relative '../../domain/juicer_machine'

module Application
  module UseCases
    class StopJuicing
      def initialize(machine)
        @machine = machine
      end

      def execute
        raise "Machine is not running" unless @machine.running?
        
        @machine.stop
        
        {
          success: true,
          message: "Juicer stopped successfully",
          state: @machine.state
        }
      rescue => e
        {
          success: false,
          message: "Failed to stop juicer: #{e.message}",
          state: @machine.state
        }
      end
    end
  end
end
