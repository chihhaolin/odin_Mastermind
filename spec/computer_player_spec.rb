require_relative 'spec_helper'

RSpec.describe ComputerPlayer do
  subject(:computer) { ComputerPlayer.new }

  describe '#generate_code' do
    it 'returns a Code object' do
      expect(computer.generate_code).to be_a(Code)
    end

    it 'returns a code with 4 colors' do
      expect(computer.generate_code.colors.length).to eq(4)
    end
  end

  describe '#make_guess' do
    it 'returns a valid Code on the first guess' do
      guess = computer.make_guess
      expect(guess).to be_a(Code)
      expect(guess.colors.length).to eq(4)
      expect(guess.colors - Code::COLORS).to be_empty
    end

    context 'after receiving feedback' do
      it 'next guess is consistent with previous feedback' do
        # secret is RRRR; guessing GGGG yields exact:0, color:0
        prev_guess    = Code.from_input('GGGG')
        prev_feedback = Feedback.new(Code.from_input('RRRR'), prev_guess)

        computer.record_feedback(prev_guess, prev_feedback)
        next_guess = computer.make_guess

        # If next_guess were the true secret, guessing GGGG must still yield the same feedback
        simulated = Feedback.new(next_guess, prev_guess)
        expect(simulated.exact).to eq(prev_feedback.exact)
        expect(simulated.color).to eq(prev_feedback.color)
      end

      it 'accumulates multiple rounds of feedback' do
        secret = Code.from_input('RRRR')

        3.times do
          guess    = computer.make_guess
          feedback = Feedback.new(secret, guess)
          computer.record_feedback(guess, feedback)
        end

        # Should still return a valid Code
        expect(computer.make_guess).to be_a(Code)
      end
    end
  end
end
