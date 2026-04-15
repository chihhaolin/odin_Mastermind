require_relative 'spec_helper'

RSpec.describe Feedback do
  def make_code(str)
    Code.from_input(str)
  end

  describe '#exact' do
    it 'returns 4 when all positions match' do
      f = Feedback.new(make_code('RGYB'), make_code('RGYB'))
      expect(f.exact).to eq(4)
    end

    it 'returns 0 when no positions match' do
      f = Feedback.new(make_code('RRRR'), make_code('GGGG'))
      expect(f.exact).to eq(0)
    end

    it 'returns correct count for partial matches' do
      # R matches, G matches, Y<->B swapped
      f = Feedback.new(make_code('RGYB'), make_code('RGBY'))
      expect(f.exact).to eq(2)
    end
  end

  describe '#color' do
    it 'counts colors in the wrong position' do
      # secret RGYB, guess GRYB: R<->G swapped → 2 exact (YB), 2 color (RG)
      f = Feedback.new(make_code('RGYB'), make_code('GRYB'))
      expect(f.exact).to eq(2)
      expect(f.color).to eq(2)
    end

    it 'does not double-count repeated colors (secret RRBB, guess RRRR)' do
      f = Feedback.new(make_code('RRBB'), make_code('RRRR'))
      expect(f.exact).to eq(2)
      expect(f.color).to eq(0)
    end

    it 'does not count exact-match positions as color matches' do
      # secret RRRR, guess RRRG: 3 exact, G not in secret → color 0
      f = Feedback.new(make_code('RRRR'), make_code('RRRG'))
      expect(f.exact).to eq(3)
      expect(f.color).to eq(0)
    end

    it 'returns 4 color matches when all colors present but all positions wrong' do
      # secret RGYB, guess YBGR → 0 exact, 4 color
      f = Feedback.new(make_code('RGYB'), make_code('YBGR'))
      expect(f.exact).to eq(0)
      expect(f.color).to eq(4)
    end
  end

  describe '#win?' do
    it 'returns true when exact == 4' do
      f = Feedback.new(make_code('RGYB'), make_code('RGYB'))
      expect(f.win?).to be true
    end

    it 'returns false when exact < 4' do
      f = Feedback.new(make_code('RGYB'), make_code('RGYP'))
      expect(f.win?).to be false
    end
  end
end
