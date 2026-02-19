# lib/application/use_cases/start_juicing.rb
require_relative 'base'

module Application
  module UseCases
    class StartJuicing < Base
      def execute
        raise "Machine not idle" unless machine.idle?
        
        machine.start
        
        success(
          message: 'Juicer started successfully',
          state: machine.state
        )
      rescue => e
        failure(
          message: "Failed to start juicer: #{e.message}",
          state: machine.state
        )
      end
    end
  end
end