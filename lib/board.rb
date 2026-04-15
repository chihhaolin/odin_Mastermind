class Board
  MAX_TURNS = 12

  def initialize
    @history = []
  end

  def record(guess, feedback)
    @history << { guess: guess, feedback: feedback }
  end

  def turns_used
    @history.length
  end

  def display
    puts "\n┌─────────────────────────────┐"
    puts "│  Turn  │  Guess  │ Feedback  │"
    puts "├─────────────────────────────┤"
    @history.each_with_index do |entry, i|
      turn   = (i + 1).to_s.rjust(3)
      guess  = entry[:guess].to_s.center(7)
      result = entry[:feedback].to_s.center(11)
      puts "│ #{turn}    │#{guess}│#{result}│"
    end
    puts "└─────────────────────────────┘\n"
  end
end
