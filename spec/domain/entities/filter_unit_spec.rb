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
  end

  describe '#filter' do
    it 'filters juice and returns volume' do
      filter = described_class.new
      volume = Domain::ValueObjects::JuiceVolume.new(100)
      
      result = filter.filter(volume)
      
      expect(result.milliliters).to eq(100)
      expect(filter.filter_count).to eq(1)
    end

    it 'increases clog level' do
      filter = described_class.new
      volume = Domain::ValueObjects::JuiceVolume.new(100)
      
      filter.filter(volume)
      
      expect(filter.clog_level).to eq(10)
    end

    it 'raises error if not idle' do
      filter = described_class.new
      filter.instance_variable_set(:@state, :filtering)
      volume = Domain::ValueObjects::JuiceVolume.new(100)
      
      expect { filter.filter(volume) }.to raise_error('Filter not idle')
    end

    it 'remains clogged after filter when threshold reached' do
      filter = described_class.new
      
      # Filter 10 times to reach clog threshold (10 * 10 = 100)
      10.times do
        volume = Domain::ValueObjects::JuiceVolume.new(100)
        filter.filter(volume)
      end
      
      # Filter should be clogged, not idle
      expect(filter.clogged?).to be true
      expect(filter.idle?).to be false
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
end