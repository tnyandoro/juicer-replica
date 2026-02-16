# lib/domain/juicer_machine.rb
require 'securerandom'
require_relative 'entities/fruit'
require_relative 'entities/juice_tank'
require_relative 'entities/waste_bin'
require_relative 'entities/press_unit'
require_relative 'entities/filter_unit'

module Domain
  class JuicerMachine
    attr_reader :id, :state, :metrics

    STATES = [:idle, :running, :cleaning, :error, :stopped].freeze

    def initialize
      @id = SecureRandom.uuid
      @state = :idle
      @press_unit = Entities::PressUnit.new
      @filter_unit = Entities::FilterUnit.new
      @juice_tank = Entities::JuiceTank.new
      @waste_bin = Entities::WasteBin.new
      @metrics = {
        fruits_processed: 0,
        total_juice_ml: 0,
        total_waste_grams: 0,
        errors: 0,
        cleaning_cycles: 0
      }
    end

    def start
      raise "Machine not idle" unless idle?
      @state = :running
    end

    def stop
      raise "Machine not running" unless running?
      @state = :stopped
    end

    def idle? = state == :idle
    def running? = state == :running
    def cleaning? = state == :cleaning
    def error? = state == :error
    def stopped? = state == :stopped

    def feed_fruit(fruit)
      raise "Machine not running" unless running?
      raise "Press unit error" if @press_unit.error?
      raise "Filter clogged" if @filter_unit.clogged?

      # Pre-compute results to validate before mutating state
      result = @press_unit.press(fruit)
      
      # FIX: Capture filtered juice result (not discarded)
      filtered_juice = @filter_unit.filter(result[:juice])

      # Pre-validate capacity BEFORE adding anything
      raise ArgumentError, "Tank would overflow" if @juice_tank.would_overflow?(filtered_juice)
      raise ArgumentError, "Bin would overflow" if @waste_bin.would_overflow?(result[:waste])

      # Now safe to mutate state - all validations passed
      # FIX: Use filtered_juice instead of original result[:juice]
      @juice_tank.add_juice(filtered_juice)
      @waste_bin.add_waste(result[:waste])

      @metrics[:fruits_processed] += 1
      # FIX: Track filtered juice volume in metrics
      @metrics[:total_juice_ml] += filtered_juice.milliliters
      @metrics[:total_waste_grams] += result[:waste]

      result
    rescue => e
      # Track errors but don't swallow them
      @metrics[:errors] += 1
      raise e
    end

    def clean
      @state = :cleaning
      @juice_tank.empty!
      @waste_bin.empty!
      @filter_unit.clean!
      @press_unit.reset
      @metrics[:cleaning_cycles] += 1
      @state = :idle
    end

    def status
      {
        state: state,
        juice_tank: {
          volume: @juice_tank.current_volume.to_s,
          capacity: @juice_tank.capacity.to_s,
          percentage: @juice_tank.percentage_full
        },
        waste_bin: {
          weight: "#{@waste_bin.current_waste}g",
          capacity: "#{@waste_bin.capacity}g",
          percentage: @waste_bin.percentage_full
        },
        press_unit: {
          state: @press_unit.state,
          press_count: @press_unit.press_count
        },
        filter_unit: {
          state: @filter_unit.state,
          filter_count: @filter_unit.filter_count,
          needs_cleaning: @filter_unit.needs_cleaning?
        },
        metrics: @metrics
      }
    end

    def reset_to_idle
      @state = :idle
      @press_unit.reset
    end
  end
end