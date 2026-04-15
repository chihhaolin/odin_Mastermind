class Feedback
  attr_reader :exact, :color

  def initialize(secret, guess)
    @exact = 0
    @color = 0
    calculate(secret.colors, guess.colors)
  end

  def win?
    @exact == 4
  end

  def to_s
    "Exact: #{@exact}, Color: #{@color}"
  end

  private

  def calculate(secret, guess)
    secret_remaining = []
    guess_remaining = []

    secret.each_with_index do |s, i|
      if s == guess[i]
        @exact += 1
      else
        secret_remaining << s
        guess_remaining << guess[i]
      end
    end

    guess_remaining.each do |g|
      idx = secret_remaining.index(g)
      next unless idx

      @color += 1
      secret_remaining.delete_at(idx)
    end
  end
end
