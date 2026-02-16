require_relative '../../domain/juicer_machine'
require_relative '../../domain/entities/fruit'

module Application
  module UseCases
    class FeedFruit
      def initialize(machine)
        @machine = machine
      end

      def execute(type:, size:, ripeness:, weight: nil)
        raise "Machine is not running" unless @machine.running?
        
        fruit = Domain::Entities::Fruit.new(
          type: type,
          size: size,
          ripeness: ripeness,
          weight: weight
        )
        
        result = @machine.feed_fruit(fruit)
        
        {
          success: true,
          message: "Fruit processed successfully",
          juice: result[:juice].to_s,
          waste: "#{result[:waste]}g",
          metrics: @machine.metrics
        }
      rescue => e
        {
          success: false,
          message: "Failed to process fruit: #{e.message}",
          juice: "0 ml",
          waste: "0g"
        }
      end
    end
  end
end
