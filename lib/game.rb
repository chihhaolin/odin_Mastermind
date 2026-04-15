class Game
  def start
    puts "╔══════════════════════════════╗"
    puts "║       MASTERMIND             ║"
    puts "╚══════════════════════════════╝"
    puts "\nColors: R(ed)  G(reen)  B(lue)  Y(ellow)  O(range)  P(urple)"
    puts "Guess a 4-color code. Colors can repeat.\n\n"

    puts "Choose your role:"
    puts "  1. Guesser    — you guess, computer sets the code"
    puts "  2. Code Maker — you set the code, computer guesses"
    print "\nEnter 1 or 2: "

    choice = gets.chomp.strip
    case choice
    when '1' then play_human_guesser
    when '2' then play_computer_guesser
    else
      puts "Invalid choice, defaulting to Guesser."
      play_human_guesser
    end
  end

  private

  def play_human_guesser
    computer = ComputerPlayer.new
    human    = HumanPlayer.new
    board    = Board.new
    secret   = computer.generate_code

    puts "\nThe computer has set a secret code."
    puts "You have #{Board::MAX_TURNS} turns. Good luck!\n"

    loop do
      puts "Turn #{board.turns_used + 1} / #{Board::MAX_TURNS}"
      guess    = human.get_guess
      feedback = Feedback.new(secret, guess)
      board.record(guess, feedback)
      board.display

      if feedback.win?
        puts "You cracked the code! The secret was #{secret}. Solved in #{board.turns_used} turn(s)!"
        break
      elsif board.turns_used >= Board::MAX_TURNS
        puts "Out of turns. The secret code was #{secret}. Better luck next time!"
        break
      end
    end
  end

  def play_computer_guesser
    human    = HumanPlayer.new
    computer = ComputerPlayer.new
    board    = Board.new

    puts "\nEnter your secret code (the computer will try to guess it)."
    secret = human.get_code

    puts "\nThe computer is thinking...\n"

    loop do
      puts "Turn #{board.turns_used + 1} / #{Board::MAX_TURNS}"
      guess    = computer.make_guess
      puts "Computer guesses: #{guess}"

      feedback = Feedback.new(secret, guess)
      computer.record_feedback(guess, feedback)
      board.record(guess, feedback)
      board.display

      if feedback.win?
        puts "The computer cracked your code #{secret} in #{board.turns_used} turn(s)!"
        break
      elsif board.turns_used >= Board::MAX_TURNS
        puts "Your code #{secret} survived #{Board::MAX_TURNS} turns! The computer failed."
        break
      end
    end
  end
end
