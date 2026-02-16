require 'spec_helper'
require 'domain/value_objects/ripeness_level'

RSpec.describe Domain::ValueObjects::RipenessLevel do
  describe '#initialize' do
    it 'creates unripe level' do
      level = described_class.new(:unripe)
      expect(level.level).to eq(:unripe)
      expect(level.unripe?).to be true
    end

    it 'creates ripe level' do
      level = described_class.new(:ripe)
      expect(level.level).to eq(:ripe)
      expect(level.ripe?).to be true
    end

    it 'creates overripe level' do
      level = described_class.new(:overripe)
      expect(level.level).to eq(:overripe)
      expect(level.overripe?).to be true
    end

    it 'raises error for invalid level' do
      expect { described_class.new(:rotten) }.to raise_error(ArgumentError)
    end
  end

  describe '#factor' do
    it 'returns 0.5 for unripe' do
      level = described_class.new(:unripe)
      expect(level.factor).to eq(0.5)
    end

    it 'returns 0.8 for ripe' do
      level = described_class.new(:ripe)
      expect(level.factor).to eq(0.8)
    end

    it 'returns 0.7 for overripe' do
      level = described_class.new(:overripe)
      expect(level.factor).to eq(0.7)
    end
  end
end