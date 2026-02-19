# lib/api/juicer_api.rb
require 'sinatra'
require 'sinatra/json'
require 'rack/cors'
require 'prometheus/client'
require_relative '../domain'
require_relative '../infrastructure/metrics'

class JuicerAPI < Sinatra::Base
  # Track request duration for all endpoints
  use Rack::Runtime, 'X-Request-Duration'
  
  before do
    @start_time = Time.now
  end
  
  after do
    duration = Time.now - @start_time
    Infrastructure::Metrics.observe_request_duration(duration)
  end

  use Rack::Cors do
    allow do
      origins '*'
      resource '*', headers: :any, methods: [:get, :post, :put, :delete, :options]
    end
  end

  set :machine, Domain::JuicerMachine.new
  set :bind, '0.0.0.0'
  set :port, 4567

  get '/health' do
    json({ status: 'healthy', timestamp: Time.now.iso8601 })
  end

  get '/status' do
    json settings.machine.status
  end

  # ✅ PROMETHEUS METRICS ENDPOINT (with error handling)
  get '/metrics' do
    begin
      content_type 'text/plain; version=0.0.4; charset=utf-8'
      
      # Update gauges with current machine state
      machine = settings.machine
      status = machine.status
      
      Infrastructure::Metrics.set_machine_state(status[:state])
      Infrastructure::Metrics.set_juice_tank_percentage(status[:juice_tank][:percentage])
      Infrastructure::Metrics.set_waste_bin_percentage(status[:waste_bin][:percentage])
      
      # Export in Prometheus format
      Infrastructure::Metrics.export
    rescue => e
      # Return minimal valid Prometheus response on error
      content_type 'text/plain; version=0.0.4; charset=utf-8'
      "# Prometheus metrics error: #{e.message}\n"
    end
  end

  post '/start' do
    result = execute_action(:start)
    
    # Track state change
    Infrastructure::Metrics.set_machine_state(:running) if result[:success]
    
    json result
  end

  post '/stop' do
    result = execute_action(:stop)
    
    # Track state change
    Infrastructure::Metrics.set_machine_state(:stopped) if result[:success]
    
    json result
  end

  post '/clean' do
    result = execute_action(:clean)
    
    # Track cleaning cycle
    Infrastructure::Metrics.cleaning_cycle_completed if result[:success]
    
    json result
  end

  post '/feed' do
    begin
      params = JSON.parse(request.body.read)
      machine = settings.machine

      unless machine.running?
        Infrastructure::Metrics.error_occurred(error_type: 'validation_error')
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

      # Track processing time
      start_time = Time.now
      result = machine.feed_fruit(fruit)
      processing_time = Time.now - start_time
      
      # ✅ EMIT PROMETHEUS METRICS
      Infrastructure::Metrics.fruits_processed(fruit_type: params['type'] || 'unknown')
      Infrastructure::Metrics.juice_produced(result[:juice].milliliters, fruit_type: params['type'] || 'unknown')
      Infrastructure::Metrics.waste_produced(result[:waste], fruit_type: params['type'] || 'unknown')

      json({
        success: true,
        message: 'Fruit processed successfully',
        juice: result[:juice].to_s,
        waste: "#{result[:waste]}g",
        metrics: machine.metrics
      })
    rescue JSON::ParserError
      Infrastructure::Metrics.error_occurred(error_type: 'json_parse_error')
      halt 400, json({
        success: false,
        message: 'Invalid JSON',
        juice: '0 ml',
        waste: '0g',
        metrics: settings.machine.metrics
      })
    rescue ArgumentError => e
      Infrastructure::Metrics.error_occurred(error_type: 'validation_error')
      halt 400, json({
        success: false,
        message: e.message,
        juice: '0 ml',
        waste: '0g',
        metrics: settings.machine.metrics
      })
    rescue => e
      Infrastructure::Metrics.error_occurred(error_type: 'internal_error')
      halt 500, json({
        success: false,
        message: "Failed to process fruit: #{e.message}",
        juice: '0 ml',
        waste: '0g',
        metrics: settings.machine.metrics
      })
    end
  end

  post '/reset' do
    settings.machine.reset_to_idle
    Infrastructure::Metrics.set_machine_state(:idle)
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
    Infrastructure::Metrics.error_occurred(error_type: 'action_error')
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