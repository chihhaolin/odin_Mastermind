require_relative 'spec_helper'

RSpec.describe Code do
  describe '.random' do
    subject(:code) { Code.random }

    it 'produces a code with 4 colors' do
      expect(code.colors.length).to eq(4)
    end

    it 'only contains valid colors' do
      expect(code.colors - Code::COLORS).to be_empty
    end

    it 'is different across multiple calls (randomness check)' do
      codes = Array.new(20) { Code.random.to_s }
      expect(codes.uniq.length).to be > 1
    end
  end

  describe '.from_input' do
    it 'correctly parses a valid string' do
      code = Code.from_input('RGYB')
      expect(code.colors).to eq(%i[R G Y B])
    end

    it 'is case-insensitive' do
      expect(Code.from_input('rgyb').colors).to eq(Code.from_input('RGYB').colors)
    end

    it 'raises ArgumentError when length is not 4' do
      expect { Code.from_input('RGY') }.to raise_error(ArgumentError)
      expect { Code.from_input('RGYBR') }.to raise_error(ArgumentError)
    end

    it 'raises ArgumentError for invalid color letters' do
      expect { Code.from_input('RGYZ') }.to raise_error(ArgumentError, /Invalid color/)
    end
  end

  describe '#to_s' do
    it 'returns an uppercase 4-character string' do
      expect(Code.from_input('rgyb').to_s).to eq('RGYB')
    end
  end
end
