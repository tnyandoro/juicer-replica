# lib/application.rb
# Application Layer - Orchestrates domain logic for external interfaces
#
# Use Cases:
# - StartJuicing: Starts the juicer machine
# - StopJuicing: Stops the juicer machine
# - CleanMachine: Runs cleaning cycle
# - FeedFruit: Processes a fruit
# - GetMetrics: Returns production metrics
# - GetStatus: Returns machine status
#
# Architecture Decision:
# - Manual requires for explicitness (6 use cases)
# - Base class for consistent interface
# - Can migrate to autoload/registry when we have 20+ use cases

require_relative 'domain'
require_relative 'application/use_cases/base'
require_relative 'application/use_cases/start_juicing'
require_relative 'application/use_cases/stop_juicing'
require_relative 'application/use_cases/clean_machine'
require_relative 'application/use_cases/feed_fruit'
require_relative 'application/use_cases/get_metrics'
require_relative 'application/use_cases/get_status'

module Application

  def self.available_use_cases
    [:start_juicing, :stop_juicing, :clean_machine, :feed_fruit, :get_metrics, :get_status]
  end
end