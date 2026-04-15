class HumanPlayer
  def get_guess
    loop do
      print "Your guess (e.g. RGYB): "
      input = gets.chomp
      return Code.from_input(input)
    rescue ArgumentError => e
      puts "  Invalid: #{e.message}"
    end
  end

  def get_code
    loop do
      print "Enter your secret code (e.g. RGYB): "
      input = gets.chomp
      return Code.from_input(input)
    rescue ArgumentError => e
      puts "  Invalid: #{e.message}"
    end
  end
end
