require 'spec_helper'
require 'domain/value_objects/fruit_size'

RSpec.describe Domain::ValueObjects::FruitSize do
  describe '#initialize' do
    it 'creates a small fruit size' do
      size = described_class.new(:small)
      expect(size.size).to eq(:small)
      expect(size.small?).to be true
    end

    it 'creates a medium fruit size' do
      size = described_class.new(:medium)
      expect(size.size).to eq(:medium)
      expect(size.medium?).to be true
    end

    it 'creates a large fruit size' do
      size = described_class.new(:large)
      expect(size.size).to eq(:large)
      expect(size.large?).to be true
    end

    it 'raises error for invalid size' do
      expect { described_class.new(:extra_large) }.to raise_error(ArgumentError)
    end
  end

  describe '#juice_factor' do
    it 'returns correct juice factor for small' do
      size = described_class.new(:small)
      expect(size.juice_factor).to eq(0.4)
    end

    it 'returns correct juice factor for medium' do
      size = described_class.new(:medium)
      expect(size.juice_factor).to eq(0.5)
    end

    it 'returns correct juice factor for large' do
      size = described_class.new(:large)
      expect(size.juice_factor).to eq(0.6)
    end
  end

  describe '#==' do
    it 'compares equal sizes correctly' do
      size1 = described_class.new(:medium)
      size2 = described_class.new(:medium)
      expect(size1).to eq(size2)
    end

    it 'compares different sizes correctly' do
      size1 = described_class.new(:small)
      size2 = described_class.new(:large)
      expect(size1).not_to eq(size2)
    end
  end
end