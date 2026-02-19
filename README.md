# 🍊 Ruby Commercial Citrus Juicer Simulator

> A production-grade simulation of a commercial citrus juicer (Zumex Versatile Basic) built with Ruby using Clean Layered Architecture, Domain-Driven Design, and Prometheus observability.

[![Tests](https://img.shields.io/badge/tests-164%20passing-brightgreen)](https://github.com/yourusername/commercial-juicer-ruby/actions)
[![Ruby](https://img.shields.io/badge/ruby-3.2.2-red)](https://www.ruby-lang.org/)
[![Architecture](https://img.shields.io/badge/architecture-clean%20layered-blue)](#-architecture)
[![Docker](https://img.shields.io/badge/docker-containerized-blue?logo=docker)](#-docker-support)
[![Prometheus](https://img.shields.io/badge/observability-prometheus-orange?logo=prometheus)](#-prometheus-metrics)
[![License](https://img.shields.io/badge/license-MIT-green)](#license)

---

## 📋 Table of Contents

- [✨ Features](#-features)
- [🏗️ Architecture](#️-architecture)
- [🚀 Quick Start](#-quick-start)
- [🎮 Usage](#-usage)
- [🧪 Testing](#-testing)
- [🐳 Docker Support](#-docker-support)
- [📊 Prometheus Metrics](#-prometheus-metrics)
- [🔧 Development](#-development)
- [🤝 Contributing](#-contributing)
- [📚 Design Decisions](#-design-decisions)
- [📄 License](#license)
- [🙏 Acknowledgments](#-acknowledgments)

---

## ✨ Features

### 🎯 Core Functionality

| Feature                | Description                                                    |
| ---------------------- | -------------------------------------------------------------- |
| 🍊 Fruit Processing    | Feed fruits with configurable type, size, ripeness, and weight |
| 🧃 Juice Extraction    | Realistic yield formulas based on fruit properties             |
| 🗑️ Waste Tracking      | Track peels, pulp, and seeds with fruit-specific ratios        |
| 🛡️ Overflow Protection | Pre-validate tank/bin capacity before state mutations          |
| 🔁 Filter Management   | Clog detection, cleaning cycles, and replacement scheduling    |
| ⚙️ Wear Simulation     | Press/filter degradation with efficiency tracking              |
| 🧹 Maintenance         | Scheduled maintenance with state recovery                      |
| 📈 Metrics             | Production metrics, efficiency calculations, error tracking    |

### 🔐 Safety & Reliability

- ✅ **Pre-validation**: All conditions checked BEFORE state mutations
- ✅ **Exception Safety**: `ensure` blocks guarantee state cleanup
- ✅ **Input Validation**: Domain entities enforce invariants at boundaries
- ✅ **Unit Consistency**: Clear documentation of grams vs milliliters
- ✅ **State Machine**: Explicit states with validated transitions

### 🌟 Advanced Features

- 🍊 **Variable Efficiency**: Orange (50%), Lemon (40%), Grapefruit (45%) juice yields
- 🌡️ **Fruit Properties**: Unique density, peel ratio, and juice factors per type
- 🔧 **Wear Tracking**: 0.1% wear per press, 0.2% per filter operation
- 📉 **Efficiency Degradation**: Press (100%→50%), Filter (100%→80%) minimums
- 🔔 **Maintenance Alerts**: Threshold-based maintenance scheduling
- 📊 **Prometheus Metrics**: 9 production-ready metrics for monitoring

---

## 🏗️ Architecture

### Clean Layered Architecture

`````text
┌─────────────────────────────────┐
│     Interface Layer              │
│  • CLI (bin/juicer_cli.rb)      │
│  • REST API (lib/api/)          │
│  • Prometheus /metrics endpoint │
└──────────────▲──────────────────┘
               │
┌──────────────┴──────────────────┐
│     Application Layer            │
│  • Use Cases (start, stop,      │
│    clean, feed, metrics)        │
│  • Orchestration logic          │
└──────────────▲──────────────────┘
               │
┌──────────────┴──────────────────┐
│     Domain Layer (Pure Ruby)    │
│  • Entities: Fruit, PressUnit,  │
│    FilterUnit, JuiceTank, etc.  │
│  • Value Objects: FruitSize,    │
│    FruitType, RipenessLevel     │
│  • JuicerMachine orchestrator   │
│  • ZERO external dependencies   │
└──────────────▲──────────────────┘
               │
┌──────────────┴──────────────────┐
│   Infrastructure Layer           │
│  • Prometheus metrics registry  │
│  • Logging, storage (optional)  │
│  • External integrations        │
└─────────────────────────────────┘

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

$ ruby bin/juicer_cli.rb

# 🍊 Commercial Citrus Juicer Simulator

State: idle | Juice: 0 ml | Waste: 0 g

Commands:
start - Start the juicer
stop - Stop the juicer
feed <params> - Feed a fruit (e.g., feed type=orange size=medium weight=150)
clean - Clean the machine
status - Show current status
metrics - Show production metrics
help - Show this help
exit - Exit the simulator

> start
> ✅ Juicer started successfully

> feed type=orange size=medium ripeness=ripe weight=150
> ✅ Fruit processed: 28.82 ml juice, 55.5 g waste

> metrics
> 📊 Production Metrics:
> Fruits processed: 1
> Total juice: 28.82 ml
> Total waste: 55.5 g
> Efficiency: 57.6%

> exit
> 👋 Goodbye!

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

## 📊 Prometheus Metrics

This project exposes Prometheus-compatible metrics for monitoring and alerting.

### Metrics Endpoint

### Available Metrics

# Scrape metrics

curl http://localhost:4567/metrics

# Example output:

# HELP juicer_fruits_processed_total Total number of fruits processed

# TYPE juicer_fruits_processed_total counter

juicer_fruits_processed_total{fruit_type="orange"} 1

# HELP juicer_juice_produced_ml_total Total juice produced in milliliters

# TYPE juicer_juice_produced_ml_total counter

juicer_juice_produced_ml_total{fruit_type="orange"} 28.82

# HELP juicer_request_duration_seconds HTTP request duration in seconds

# TYPE juicer_request_duration_seconds histogram

juicer_request_duration_seconds_bucket{le="0.01"} 1
juicer_request_duration_seconds_bucket{le="0.05"} 1
...

### Example Query (PromQL)

```promql
# Fruits processed per minute
rate(juicer_fruits_processed_total[1m])

# Error rate
rate(juicer_errors_total[5m])

# Average request duration
rate(juicer_request_duration_seconds_sum[5m]) / rate(juicer_request_duration_seconds_count[5m])
```

# All tests (164 examples)

bundle exec rspec

# Specific test files

bundle exec rspec spec/domain/entities/fruit_spec.rb
bundle exec rspec spec/api/metrics_spec.rb

# With documentation format

bundle exec rspec --format documentation

# With coverage report

bundle exec rspec --format progress --require simplecov

MIT License

Copyright (c) 2025 Tendai Nyandoro

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
