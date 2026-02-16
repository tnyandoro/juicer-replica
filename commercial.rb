# Main library entry point

require_relative 'domain'
require_relative 'application'

# Optional: Add infrastructure when needed
# require_relative 'infrastructure'

module CommercialJuicer
  VERSION = '0.1.0'
  
  def self.machine
    Domain::JuicerMachine.new
  end
end