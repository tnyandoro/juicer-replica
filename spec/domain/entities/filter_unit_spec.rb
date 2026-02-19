require 'spec_helper'
require 'domain/entities/filter_unit'
require 'domain/value_objects/juice_volume'

RSpec.describe Domain::Entities::FilterUnit do
  describe '#initialize' do
    it 'starts in idle state' do
      filter = described_class.new
      expect(filter.state).to eq(:idle)
      expect(filter.idle?).to be true
    end

    it 'has zero filter count' do
      filter = described_class.new
      expect(filter.filter_count).to eq(0)
    end

    it 'has zero clog level' do
      filter = described_class.new
      expect(filter.clog_level).to eq(0)
    end

    # ✅ NEW: Wear and Tear Tests
    it 'starts with 0% wear' do
      filter = described_class.new
      expect(filter.wear_percentage).to eq(0.0)
    end
  end

  describe '#filter' do
    it 'filters juice and returns volume' do
      filter = described_class.new
      volume = Domain::ValueObjects::JuiceVolume.new(100)
      
      result = filter.filter(volume)
      
      # ✅ CHANGED: Allow small efficiency loss (wear = 0.2%, efficiency = 99.9%)
      expect(result.milliliters).to be_within(0.1).of(100)
      expect(filter.filter_count).to eq(1)
    end

    it 'increases clog level' do
      filter = described_class.new
      volume = Domain::ValueObjects::JuiceVolume.new(100)
      
      filter.filter(volume)
      
      # ✅ CHANGED: 5.0 instead of 10 (CLOG_PER_FILTER = 5)
      expect(filter.clog_level).to eq(5.0)
    end

    it 'raises error if not idle' do
      filter = described_class.new
      filter.instance_variable_set(:@state, :filtering)
      volume = Domain::ValueObjects::JuiceVolume.new(100)
      
      expect { filter.filter(volume) }.to raise_error('Filter not idle')
    end

    it 'remains clogged after filter when threshold reached' do
      filter = described_class.new
      
      # ✅ CHANGED: 16 times to reach clog threshold (16 * 5 = 80)
      16.times do
        volume = Domain::ValueObjects::JuiceVolume.new(100)
        filter.filter(volume)
      end
      
      # Filter should be clogged, not idle
      expect(filter.clogged?).to be true
      expect(filter.idle?).to be false
    end

    # ✅ NEW: Wear and Tear Tests
    it 'increases wear level with each filter operation' do
      filter = described_class.new
      volume = Domain::ValueObjects::JuiceVolume.new(100)
      
      filter.filter(volume)
      
      expect(filter.wear_percentage).to be > 0
    end

    it 'decreases filtration efficiency as wear increases' do
      filter = described_class.new
      filter.instance_variable_set(:@wear_level, 40)
      
      expect(filter.filtration_efficiency_percentage).to eq(80.0)
    end

    it 'has minimum 80% filtration efficiency' do
      filter = described_class.new
      filter.instance_variable_set(:@wear_level, 100)
      
      expect(filter.filtration_efficiency_percentage).to eq(80.0)
    end

    it 'applies filtration efficiency to output volume' do
      filter = described_class.new
      filter.instance_variable_set(:@wear_level, 40)  # 80% efficiency
      volume = Domain::ValueObjects::JuiceVolume.new(100)
      
      result = filter.filter(volume)
      
      expect(result.milliliters).to eq(80.0)  # 80% of 100ml
    end

    it 'raises error when filter needs replacement' do
      filter = described_class.new
      filter.instance_variable_set(:@filter_count, 500)
      volume = Domain::ValueObjects::JuiceVolume.new(100)
      
      expect { filter.filter(volume) }.to raise_error('Filter needs replacement')
    end
  end

  describe '#check_clog!' do
    it 'sets state to clogged when threshold reached' do
      filter = described_class.new
      filter.instance_variable_set(:@clog_level, 100)
      filter.check_clog!
      expect(filter.clogged?).to be true
    end
  end

  describe '#clean!' do
    it 'resets clog level and state' do
      filter = described_class.new
      filter.instance_variable_set(:@clog_level, 50)
      filter.instance_variable_set(:@state, :clogged)
      
      filter.clean!
      
      expect(filter.clog_level).to eq(0)
      expect(filter.idle?).to be true
    end
  end

  describe '#needs_cleaning?' do
    it 'returns true when clog level is at 80%' do
      filter = described_class.new
      filter.instance_variable_set(:@clog_level, 80)
      expect(filter.needs_cleaning?).to be true
    end

    it 'returns false when clog level is below 80%' do
      filter = described_class.new
      filter.instance_variable_set(:@clog_level, 50)
      expect(filter.needs_cleaning?).to be false
    end
  end

  # ✅ NEW: Maintenance Tests
  describe '#needs_replacement?' do
    it 'returns false when new' do
      filter = described_class.new
      expect(filter.needs_replacement?).to be false
    end

    it 'returns true when filter count exceeds max' do
      filter = described_class.new
      filter.instance_variable_set(:@filter_count, 500)
      
      expect(filter.needs_replacement?).to be true
    end

    it 'returns true when wear reaches 100%' do
      filter = described_class.new
      filter.instance_variable_set(:@wear_level, 100)
      
      expect(filter.needs_replacement?).to be true
    end
  end

  describe '#replace_filter' do
    it 'resets wear to 0%' do
      filter = described_class.new
      filter.instance_variable_set(:@wear_level, 50)
      filter.replace_filter
      
      expect(filter.wear_percentage).to eq(0.0)
    end

    it 'resets filter count to 0' do
      filter = described_class.new
      filter.instance_variable_set(:@filter_count, 250)
      filter.replace_filter
      
      expect(filter.filter_count).to eq(0)
    end

    it 'resets clog level to 0' do
      filter = described_class.new
      filter.instance_variable_set(:@clog_level, 50)
      filter.replace_filter
      
      expect(filter.clog_level).to eq(0)
    end

    it 'resets state to idle' do
      filter = described_class.new
      filter.instance_variable_set(:@state, :clogged)
      filter.replace_filter
      
      expect(filter.idle?).to be true
    end
  end

  describe '#needs_maintenance?' do
    it 'returns false when new' do
      filter = described_class.new
      expect(filter.needs_maintenance?).to be false
    end

    it 'returns true when filter needs replacement' do
      filter = described_class.new
      filter.instance_variable_set(:@filter_count, 500)
      
      expect(filter.needs_maintenance?).to be true
    end

    it 'returns true when filter is clogged' do
      filter = described_class.new
      filter.instance_variable_set(:@state, :clogged)
      
      expect(filter.needs_maintenance?).to be true
    end
  end
end