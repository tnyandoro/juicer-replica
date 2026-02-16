require_relative '../../domain/juicer_machine'

module Application
  module UseCases
    class StartJuicing
      def initialize(machine)
        @machine = machine
      end

      def execute
        raise "Machine is not idle" unless @machine.idle?
        
        @machine.start
        
        {
          success: true,
          message: "Juicer started successfully",
          state: @machine.state
        }
      rescue => e
        {
          success: false,
          message: "Failed to start juicer: #{e.message}",
          state: @machine.state
        }
      end
    end
  end
end
