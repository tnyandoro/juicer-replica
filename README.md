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
```

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
