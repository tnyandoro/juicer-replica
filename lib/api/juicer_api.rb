require 'sinatra'
require 'sinatra/json'
require 'rack/cors'
require_relative '../domain'

class JuicerAPI < Sinatra::Base
  # Enable CORS
  use Rack::Cors do
    allow do
      origins '*'
      resource '*', headers: :any, methods: [:get, :post, :put, :delete, :options]
    end
  end

  # Initialize machine
  set :machine, Domain::JuicerMachine.new
  set :bind, '0.0.0.0'
  set :port, 4567

  # Health check
  get '/health' do
    json({ status: 'healthy', timestamp: Time.now.iso8601 })
  end

  # Get machine status
  get '/status' do
    json settings.machine.status
  end

  # Get metrics
  get '/metrics' do
    status = settings.machine.status
    json({
      success: true,
      state: status[:state],
      metrics: status[:metrics],
      juice_tank: status[:juice_tank],
      waste_bin: status[:waste_bin],
      efficiency: calculate_efficiency(status[:metrics])
    })
  end

  # Start machine
  post '/start' do
    result = execute_action(:start)
    json result
  end

  # Stop machine
  post '/stop' do
    result = execute_action(:stop)
    json result
  end

  # Clean machine
  post '/clean' do
    result = execute_action(:clean)
    json result
  end

  # Feed fruit
  post '/feed' do
    begin
      params = JSON.parse(request.body.read)
      machine = settings.machine

      # Check machine state BEFORE creating fruit
      unless machine.running?
        halt 400, json({
          success: false,
          message: 'Machine not running',
          juice: '0 ml',
          waste: '0g',
          metrics: machine.metrics
        })
      end

      fruit = Domain::Entities::Fruit.new(
        type: params['type']&.to_sym || :orange,
        size: params['size']&.to_sym || :medium,
        ripeness: params['ripeness']&.to_sym || :ripe,
        weight: params['weight']&.to_i
      )

      result = machine.feed_fruit(fruit)

      json({
        success: true,
        message: 'Fruit processed successfully',
        juice: result[:juice].to_s,
        waste: "#{result[:waste]}g",
        metrics: machine.metrics
      })
    rescue JSON::ParserError
      halt 400, json({
        success: false,
        message: 'Invalid JSON',
        juice: '0 ml',
        waste: '0g',
        metrics: settings.machine.metrics
      })
    rescue ArgumentError => e
      halt 400, json({
        success: false,
        message: e.message,
        juice: '0 ml',
        waste: '0g',
        metrics: settings.machine.metrics
      })
    rescue => e
      halt 500, json({
        success: false,
        message: "Failed to process fruit: #{e.message}",
        juice: '0 ml',
        waste: '0g',
        metrics: settings.machine.metrics
      })
    end
  end

  # Reset machine
  post '/reset' do
    settings.machine.reset_to_idle
    json({ success: true, message: 'Machine reset to idle', state: :idle })
  end

  private

  def execute_action(action)
    machine = settings.machine

    case action
    when :start
      machine.start
      { success: true, message: 'Juicer started successfully', state: machine.state }
    when :stop
      machine.stop
      { success: true, message: 'Juicer stopped successfully', state: machine.state }
    when :clean
      machine.clean
      { success: true, message: 'Machine cleaned successfully', state: machine.state, cleaning_cycles: machine.metrics[:cleaning_cycles] }
    end
  rescue => e
    { success: false, message: e.message, state: machine.state }
  end

  def calculate_efficiency(metrics)
    return 0.0 if metrics[:fruits_processed] == 0
    juice_per_fruit = metrics[:total_juice_ml].to_f / metrics[:fruits_processed]
    expected_yield = 50.0
    ((juice_per_fruit / expected_yield) * 100).round(2)
  end
end

if __FILE__ == $PROGRAM_NAME
  JuicerAPI.run!
end