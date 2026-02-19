module Application
  module UseCases
    class Base
      attr_reader :machine

      def initialize(machine)
        @machine = machine
      end

      def execute(**args)
        raise NotImplementedError, 'Subclasses must implement #execute'
      end

      protected

      def success(data = {})
        { success: true, **data }
      end

      def failure(message, data = {})
        { success: false, message: message, **data }
      end
    end
  end
end