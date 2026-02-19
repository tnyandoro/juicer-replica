# Ruby Commercial Citrus Juicer Simulator

A production-grade simulation of a commercial citrus juicer (Zumex Versatile Basic) built with Ruby using Clean Layered Architecture and Domain-Driven Design.

![Tests](https://img.shields.io/badge/tests-108%20passing-brightgreen)
![Ruby](https://img.shields.io/badge/ruby-3.2.2-red)
![Architecture](https://img.shields.io/badge/architecture-clean%20layered-blue)
![Docker](https://img.shields.io/badge/docker-containerized-blue?logo=docker)
…- Domain-Driven Design

- Comprehensive test coverage (108 tests)
- Code review-driven improvements (8 CodeRabbit fixes)

---

## Architecture

`````text

┌──────────────────────────┐
│ Interface Layer │ CLI / API / Web UI
│ (bin/juicer_cli.rb) │
└──────────────▲───────────┘
│
┌──────────────┴───────────┐
│ Application Layer │ Use Cases & Orchestration
│ (lib/application/) │
└──────────────▲───────────┘
│
┌──────────────┴───────────┐
│ Domain Layer │ Core Business Logic
│ (lib/domain/) │ (Pure Ruby, No Dependencies)
└──────────────▲───────────┘
│
┌──────────────┴───────────┐
│ Infrastructure Layer │ Logging, Storage, Sensors
│ (lib/infrastructure/) │
└──────────────────────────┘

### Clean Layered Architecture

### Why This Architecture?

| Benefit                    | Explanation                                     |
| -------------------------- | ----------------------------------------------- |
| **Separation of Concerns** | Business logic isolated from UI and storage     |
| **Testability**            | Domain layer can be tested without dependencies |
| **Extensibility**          | Easy to add API, Web UI, or IoT integration     |
| **Maintainability**        | Clear boundaries make code easier to understand |

---

## :star Features

### Core Features

-  Fruit feeding with size, type, and ripeness parameters
-  Juice extraction with realistic yield formulas
-  Waste tracking (peels, pulp, seeds)
-  Tank overflow protection
-  Filter clog detection and cleaning cycles
-  Error state management and recovery
-  Production metrics and efficiency tracking

### Safety Features

-  Pre-validation before state mutations (no partial updates)
-  Exception-safe state management (ensure blocks)
-  Input validation (positive values, valid states)
-  Unit consistency (grams vs milliliters documented)

---

## Installation

````bash
# Clone the repository
git clone <repository-url>
cd commercial-juicer-ruby

# Install dependencies
bundle install

# Run tests
bundle exec rspec

# Start the CLI
ruby bin/juicer_cli.rb


# Ruby Commercial Citrus Juicer

Simulation of a commercial citrus juicer (Zumex Versatile Basic) using Clean Layered Architecture.

## Architecture

- **Domain:** Core logic (JuicerMachine, Fruit, PressUnit)
- **Application:** Use Cases (Start, Stop, Clean)
- **Infrastructure:** Logging, Storage, Sensors Mock
- **Interface:** CLI

## Setup

```bash
bundle install
`````

# juicer-replica

## Design Tradeoff: Unit Conversion

**Decision:** Use 1.0 g/ml density approximation for juice

**Rationale:**

- Simplifies simulation logic
- Error margin is small (~4-5% for citrus juice)
- Acceptable for MVP simulation

**Future Improvement:**

- Add configurable density per fruit type
- Orange: 1.04 g/ml
- Lemon: 1.03 g/ml
- Grapefruit: 1.05 g/ml

## State Management & Exception Safety

**Problem:** State machines can get stuck in intermediate states if exceptions occur.

**Solution:** Use Ruby's `ensure` block to guarantee state cleanup.

**Code Pattern:**

```ruby
def press(fruit)
  @state = :pressing
  # ... operations that might raise ...
ensure
  @state = :idle if @state == :pressing
end
```

## State Management & Exception Safety

**Problem:** State machines can get stuck in intermediate states if exceptions occur.

**Solution:** Use Ruby's `ensure` block to guarantee state cleanup.

**Code Pattern:**

```ruby
def press(fruit)
  @state = :pressing
  # ... operations that might raise ...
ensure
  @state = :idle if @state == :pressing
end
```

## Input Validation & Domain Invariants

**Problem:** Domain entities must protect their internal state from invalid inputs.

**Solution:** Validate at the boundary (method entry point).

**Code Pattern:**

```ruby
def add_waste(grams)
  raise ArgumentError, "Grams must be positive" unless grams > 0
  # ... rest of logic
end
```

## Input Validation & Domain Invariants

**Problem:** Domain entities must protect their internal state from invalid inputs.

**Solution:** Validate at the boundary (method entry point).

**Code Pattern:**

```ruby
def add_waste(grams)
  raise ArgumentError, "Grams must be positive" unless grams > 0
  # ... rest of logic
end
```

## State Consistency & Transactional Operations

**Problem:** Multi-step operations can leave the system in an inconsistent
state if any step fails.

**Solution:** Pre-validate all conditions BEFORE mutating state.

**Code Pattern:**

```ruby
def feed_fruit(fruit)
  # 1. Validate preconditions
  raise "Machine not running" unless running?

  # 2. Compute results (read-only)
  result = @press_unit.press(fruit)

  # 3. Pre-validate capacity (read-only checks)
  raise "Tank would overflow" if @juice_tank.would_overflow?(result[:juice])

  # 4. Mutate state (all validations passed)
  @juice_tank.add_juice(result[:juice])
  @waste_bin.add_waste(result[:waste])
end
```

## Project Structure

```text

commercial-juicer-ruby/
├── bin/
│ └── juicer_cli.rb # Interactive CLI
├── lib/
│ ├── domain/
│ │ ├── entities/
│ │ │ ├── fruit.rb # Fruit entity
│ │ │ ├── juice_tank.rb # Juice storage
│ │ │ ├── waste_bin.rb # Waste tracking
│ │ │ ├── press_unit.rb # Squeezing logic
│ │ │ └── filter_unit.rb # Filtering logic
│ │ ├── value_objects/
│ │ │ ├── fruit_size.rb # Size enum
│ │ │ ├── ripeness_level.rb # Ripeness enum
│ │ │ └── juice_volume.rb # Volume value object
│ │ └── juicer_machine.rb # Main orchestrator
│ ├── application/
│ │ └── use_cases/
│ │ ├── start_juicing.rb # Start use case
│ │ ├── stop_juicing.rb # Stop use case
│ │ ├── clean_machine.rb # Clean use case
│ │ ├── feed_fruit.rb # Feed use case
│ │ ├── get_metrics.rb # Metrics use case
│ │ └── get_status.rb # Status use case
│ ├── infrastructure/
│ │ ├── logger.rb # Logging (optional)
│ │ └── storage.rb # Persistence (optional)
│ ├── domain.rb # Domain entry point
│ └── application.rb # Application entry point
├── spec/
│ ├── domain/
│ ├── application/
│ ├── integration/
│ └── spec_helper.rb
├── Gemfile
├── README.md
└── .rspec
```

### Current Approach: Base Class + Manual Requires

**Pros:**

- Explicit dependencies (easy to trace)
- Consistent interface (success/failure helpers)
- Easy to debug (no magic)
- Fast startup (no file system scanning)

**Cons:**

- Manual requires (must update when adding use cases)
- No auto-discovery

**When to Evolve:**

- 20+ use cases → Migrate to `autoload`
- 50+ use cases → Add registry pattern
- 100+ use cases → Split into separate gems

**Rationale:**
Following YAGNI principle. Current complexity matches current scale.
Architecture is designed to evolve without breaking changes.

## 🐳 Docker Support

This project is fully containerized for easy deployment and testing.

### Prerequisites

- Docker 20.10+
- Docker Compose 2.0+

### Quick Start

```bash
# Run all tests in Docker
docker-compose run juicer

# Start API server in Docker
docker-compose up juicer-api

# Run CLI in Docker
docker-compose run juicer ruby bin/juicer_cli.rb

# Run specific tests
docker-compose run juicer bundle exec rspec spec/domain/

docker-compose run --rm juicer bundle exec rspec

…# Stop API server
docker-compose down
```
