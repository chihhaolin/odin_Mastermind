class ComputerPlayer
  def initialize
    @history = []  # Array of [guess, feedback]
  end

  def generate_code
    Code.random
  end

  def make_guess
    return Code.random if @history.empty?

    find_consistent_guess
  end

  def record_feedback(guess, feedback)
    @history << [guess, feedback]
  end

  private

  def find_consistent_guess
    1000.times do
      candidate = Code.random
      return candidate if consistent?(candidate)
    end
    Code.random
  end

  def consistent?(candidate)
    @history.all? do |prev_guess, prev_feedback|
      simulated = Feedback.new(candidate, prev_guess)
      simulated.exact == prev_feedback.exact && simulated.color == prev_feedback.color
    end
  end
end
