require_relative '../../domain/juicer_machine'

module Application
  module UseCases
    class GetStatus
      def initialize(machine)
        @machine = machine
      end

      def execute
        {
          success: true,
          status: @machine.status
        }
      rescue => e
        {
          success: false,
          message: "Failed to get status: #{e.message}"
        }
      end
    end
  end
end
