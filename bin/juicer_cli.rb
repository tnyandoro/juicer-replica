#!/usr/bin/env ruby
# bin/juicer_cli.rb
# Interactive CLI for Commercial Citrus Juicer Simulation

require 'bundler/setup'
require_relative '../lib/domain'
require_relative '../lib/application'

class JuicerCLI
  attr_reader :machine, :use_cases

  def initialize
    @machine = Domain::JuicerMachine.new
    @use_cases = {
      start: Application::UseCases::StartJuicing.new(@machine),
      stop: Application::UseCases::StopJuicing.new(@machine),
      clean: Application::UseCases::CleanMachine.new(@machine),
      feed: Application::UseCases::FeedFruit.new(@machine),
      metrics: Application::UseCases::GetMetrics.new(@machine),
      status: Application::UseCases::GetStatus.new(@machine)
    }
    @running = true
  end

  def start
    show_banner
    show_help
    
    while @running
      print "\n🍊 juicer> "
      command = gets&.strip&.downcase
      break if command.nil? || command == 'quit' || command == 'exit'
      
      process_command(command)
    end
    
    puts "\n👋 Goodbye! Thanks for using Ruby Commercial Juicer!\n"
  end

  private

  def show_banner
    puts "\n" + "=" * 60
    puts "  🍊 Ruby Commercial Citrus Juicer Simulator"
    puts "  Zumex Versatile Basic Edition"
    puts "=" * 60
  end

  def show_help
    puts "\n📖 Available Commands:"
    puts "  start              - Start the juicer machine"
    puts "  stop               - Stop the juicer machine"
    puts "  feed <type> <size> <ripeness> [weight]"
    puts "                     - Feed a fruit (e.g., feed orange medium ripe 150)"
    puts "  status             - Show current machine status"
    puts "  metrics            - Show production metrics"
    puts "  clean              - Run cleaning cycle"
    puts "  help               - Show this help message"
    puts "  quit/exit          - Exit the simulator"
    puts "\n📝 Fruit Types: orange, lemon, grapefruit"
    puts "📏 Sizes: small, medium, large"
    puts "🎯 Ripeness: unripe, ripe, overripe"
  end

  def process_command(command)
    parts = command.split
    
    case parts[0]
    when 'start'
      execute_use_case(:start)
    when 'stop'
      execute_use_case(:stop)
    when 'clean'
      execute_use_case(:clean)
    when 'status'
      execute_use_case(:status)
    when 'metrics'
      execute_use_case(:metrics)
    when 'feed'
      process_feed_command(parts[1..-1])
    when 'help'
      show_help
    when 'quit', 'exit'
      @running = false
    else
      puts "❌ Unknown command: #{parts[0]}. Type 'help' for available commands."
    end
  end

  def execute_use_case(name)
    result = @use_cases[name].execute
    
    if result[:success]
      puts "✅ #{result[:message]}"
      display_result(result)
    else
      puts "❌ #{result[:message]}"
    end
  rescue => e
    puts "❌ Error: #{e.message}"
  end

  def process_feed_command(args)
    if args.nil? || args.length < 3
      puts "❌ Usage: feed <type> <size> <ripeness> [weight]"
      puts "   Example: feed orange medium ripe 150"
      return
    end
    
    type = args[0]&.to_sym
    size = args[1]&.to_sym
    ripeness = args[2]&.to_sym
    weight = args[3]&.to_i
    
    # Validate inputs
    valid_types = [:orange, :lemon, :grapefruit]
    valid_sizes = [:small, :medium, :large]
    valid_ripeness = [:unripe, :ripe, :overripe]
    
    unless valid_types.include?(type)
      puts "❌ Invalid fruit type. Choose from: #{valid_types.join(', ')}"
      return
    end
    
    unless valid_sizes.include?(size)
      puts "❌ Invalid size. Choose from: #{valid_sizes.join(', ')}"
      return
    end
    
    unless valid_ripeness.include?(ripeness)
      puts "❌ Invalid ripeness. Choose from: #{valid_ripeness.join(', ')}"
      return
    end
    
    result = @use_cases[:feed].execute(
      type: type,
      size: size,
      ripeness: ripeness,
      weight: weight
    )
    
    if result[:success]
      puts "✅ #{result[:message]}"
      puts "   🧃 Juice: #{result[:juice]}"
      puts "   🗑️  Waste: #{result[:waste]}"
    else
      puts "❌ #{result[:message]}"
    end
  rescue => e
    puts "❌ Error: #{e.message}"
  end

  def display_result(result)
    case result.keys
    when Array
      # Status display
      if result[:status]
        status = result[:status]
        puts "\n📊 Machine Status:"
        puts "   State: #{status[:state].to_s.upcase}"
        puts "\n   🧃 Juice Tank:"
        puts "      Volume: #{status[:juice_tank][:volume]}"
        puts "      Capacity: #{status[:juice_tank][:capacity]}"
        puts "      Full: #{status[:juice_tank][:percentage]}%"
        puts "\n   🗑️  Waste Bin:"
        puts "      Weight: #{status[:waste_bin][:weight]}"
        puts "      Capacity: #{status[:waste_bin][:capacity]}"
        puts "      Full: #{status[:waste_bin][:percentage]}%"
        puts "\n   ⚙️  Press Unit:"
        puts "      State: #{status[:press_unit][:state]}"
        puts "      Press Count: #{status[:press_unit][:press_count]}"
        puts "\n   🔍 Filter Unit:"
        puts "      State: #{status[:filter_unit][:state]}"
        puts "      Filter Count: #{status[:filter_unit][:filter_count]}"
        puts "      Needs Cleaning: #{status[:filter_unit][:needs_cleaning]}"
      end
      
      # Metrics display
      if result[:metrics]
        metrics = result[:metrics]
        puts "\n📈 Production Metrics:"
        puts "   Fruits Processed: #{metrics[:fruits_processed]}"
        puts "   Total Juice: #{metrics[:total_juice_ml].round(2)} ml"
        puts "   Total Waste: #{metrics[:total_waste_grams].round(2)} g"
        puts "   Cleaning Cycles: #{metrics[:cleaning_cycles]}"
        puts "   Errors: #{metrics[:errors]}"
        puts "   Efficiency: #{result[:efficiency]}%" if result[:efficiency]
      end
    end
  end
end

# Run the CLI
if __FILE__ == $PROGRAM_NAME
  cli = JuicerCLI.new
  cli.start
end