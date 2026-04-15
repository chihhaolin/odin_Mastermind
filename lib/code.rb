class Code
  COLORS = %i[R G B Y O P].freeze
  COLOR_MAP = { 'R' => :R, 'G' => :G, 'B' => :B, 'Y' => :Y, 'O' => :O, 'P' => :P }.freeze

  attr_reader :colors

  def initialize(colors)
    @colors = colors
  end

  def self.random
    new(Array.new(4) { COLORS.sample })
  end

  def self.from_input(string)
    chars = string.upcase.chars
    raise ArgumentError, "Must be exactly 4 colors" unless chars.length == 4

    chars.each do |c|
      raise ArgumentError, "Invalid color '#{c}'. Valid: R G B Y O P" unless COLOR_MAP.key?(c)
    end

    new(chars.map { |c| COLOR_MAP[c] })
  end

  def to_s
    @colors.map(&:to_s).join
  end

  def ==(other)
    colors == other.colors
  end
end
