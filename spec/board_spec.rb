require_relative 'spec_helper'

RSpec.describe Board do
  subject(:board) { Board.new }

  let(:guess)    { Code.from_input('RGYB') }
  let(:feedback) { Feedback.new(Code.from_input('RRRR'), guess) }

  describe '#turns_used' do
    it 'starts at 0' do
      expect(board.turns_used).to eq(0)
    end

    it 'increments by 1 after each record' do
      board.record(guess, feedback)
      expect(board.turns_used).to eq(1)

      board.record(guess, feedback)
      expect(board.turns_used).to eq(2)
    end
  end

  describe '#record' do
    it 'stores the guess and feedback' do
      board.record(guess, feedback)
      expect(board.turns_used).to eq(1)
    end
  end

  describe 'MAX_TURNS' do
    it 'is 12' do
      expect(Board::MAX_TURNS).to eq(12)
    end
  end
end
