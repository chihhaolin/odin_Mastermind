require_relative '../lib/code'
require_relative '../lib/feedback'
require_relative '../lib/board'
require_relative '../lib/computer_player'

# Bridges Plain-Hash session storage and domain objects.
# All public methods that mutate state also update the internal hash so that
# #to_h always returns a complete, up-to-date snapshot ready to be stored in
# the Rack session cookie.
class GameSession
  MAX_TURNS = Board::MAX_TURNS

  # ── Factory methods ─────────────────────────────────────────────────────

  def self.new_guesser_game
    secret = Code.random
    {
      role:             'guesser',
      secret:           secret.colors.map(&:to_s),
      history:          [],
      computer_history: [],
      status:           'playing',
      error:            nil
    }
  end

  def self.new_maker_game(secret_str)
    secret = Code.from_input(secret_str)   # raises ArgumentError on bad input
    {
      role:             'maker',
      secret:           secret.colors.map(&:to_s),
      history:          [],
      computer_history: [],
      status:           'playing',
      error:            nil
    }
  end

  # Rebuild a GameSession from a stored hash (symbol or string keys accepted).
  def self.from_hash(h)
    new(normalize(h))
  end

  # ── Instance ────────────────────────────────────────────────────────────

  def initialize(hash)
    @h = hash
  end

  # Human submits a guess (guesser mode).
  # Returns { ok: Bool, error: String|nil, feedback: Hash|nil, status: String }
  def submit_guess(input_str)
    return already_over_result if @h[:status] != 'playing'

    begin
      guess = Code.from_input(input_str)
    rescue ArgumentError => e
      @h[:error] = e.message
      return { ok: false, error: e.message, status: @h[:status] }
    end

    @h[:error] = nil
    secret   = Code.new(@h[:secret].map(&:to_sym))
    feedback = Feedback.new(secret, guess)

    @h[:history] << {
      guess: guess.colors.map(&:to_s),
      exact: feedback.exact,
      color: feedback.color
    }

    update_status(feedback)
    { ok: true, error: nil, feedback: { exact: feedback.exact, color: feedback.color }, status: @h[:status] }
  end

  # Computer takes one guess (maker mode).
  # Returns { guess: String, feedback: Hash, status: String }
  def computer_guess
    return already_over_result if @h[:status] != 'playing'

    computer = rebuild_computer_player
    guess    = computer.make_guess
    secret   = Code.new(@h[:secret].map(&:to_sym))
    feedback = Feedback.new(secret, guess)

    computer.record_feedback(guess, feedback)

    @h[:computer_history] << {
      guess: guess.colors.map(&:to_s),
      exact: feedback.exact,
      color: feedback.color
    }
    @h[:history] << {
      guess: guess.colors.map(&:to_s),
      exact: feedback.exact,
      color: feedback.color
    }

    update_status(feedback)
    { guess: guess.to_s, feedback: { exact: feedback.exact, color: feedback.color }, status: @h[:status] }
  end

  # Rows ready for the View: [{turn:, guess:, exact:, color:}, …]
  def board_rows
    @h[:history].each_with_index.map do |entry, i|
      {
        turn:  i + 1,
        guess: entry[:guess].join,
        exact: entry[:exact],
        color: entry[:color]
      }
    end
  end

  def turns_used  = @h[:history].length
  def max_turns   = MAX_TURNS
  def role        = @h[:role]
  def status      = @h[:status]
  def secret      = @h[:secret].join
  def error       = @h[:error]

  # Serialize back to a plain Hash for session storage.
  def to_h
    @h.dup
  end

  # ── Private ─────────────────────────────────────────────────────────────

  private

  def update_status(feedback)
    if feedback.win?
      @h[:status] = 'won'
    elsif @h[:history].length >= MAX_TURNS
      @h[:status] = 'lost'
    end
  end

  def already_over_result
    { ok: false, error: 'Game is already over.', status: @h[:status] }
  end

  # Reconstruct a ComputerPlayer seeded with all previous guesses/feedback.
  def rebuild_computer_player
    cp = ComputerPlayer.new
    @h[:computer_history].each do |entry|
      guess    = Code.new(entry[:guess].map(&:to_sym))
      feedback = FeedbackStub.new(entry[:exact], entry[:color])
      cp.record_feedback(guess, feedback)
    end
    cp
  end

  # Lightweight stand-in so we can replay history without recalculating.
  FeedbackStub = Struct.new(:exact, :color)

  def self.normalize(h)
    # Accept symbol or string keys, always store as symbols internally.
    result = {}
    %i[role secret history computer_history status error].each do |key|
      result[key] = h[key] || h[key.to_s]
    end
    result[:history]          = (result[:history] || []).map { |e| symbolize(e) }
    result[:computer_history] = (result[:computer_history] || []).map { |e| symbolize(e) }
    result
  end

  def self.symbolize(entry)
    { guess: entry[:guess] || entry['guess'],
      exact: entry[:exact] || entry['exact'],
      color: entry[:color] || entry['color'] }
  end
end
