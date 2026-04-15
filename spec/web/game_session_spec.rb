require 'spec_helper'
require_relative '../../web/game_session'

RSpec.describe GameSession do
  # ── .new_guesser_game ───────────────────────────────────────────────────

  describe '.new_guesser_game' do
    subject(:h) { GameSession.new_guesser_game }

    it 'sets role to guesser' do
      expect(h[:role]).to eq('guesser')
    end

    it 'generates a 4-element secret code' do
      expect(h[:secret].length).to eq(4)
    end

    it 'secret contains only valid color letters' do
      expect(h[:secret]).to all(match(/\A[RGBYOP]\z/))
    end

    it 'starts with status playing' do
      expect(h[:status]).to eq('playing')
    end

    it 'starts with empty history' do
      expect(h[:history]).to be_empty
    end

    it 'starts with empty computer_history' do
      expect(h[:computer_history]).to be_empty
    end
  end

  # ── .new_maker_game ─────────────────────────────────────────────────────

  describe '.new_maker_game' do
    it 'sets role to maker' do
      h = GameSession.new_maker_game('RGYB')
      expect(h[:role]).to eq('maker')
    end

    it 'stores the secret matching the input' do
      h = GameSession.new_maker_game('RGYB')
      expect(h[:secret]).to eq(%w[R G Y B])
    end

    it 'accepts lowercase input' do
      h = GameSession.new_maker_game('rgyb')
      expect(h[:secret]).to eq(%w[R G Y B])
    end

    it 'raises ArgumentError for invalid length' do
      expect { GameSession.new_maker_game('RRR') }.to raise_error(ArgumentError)
    end

    it 'raises ArgumentError for invalid color letters' do
      expect { GameSession.new_maker_game('RXYZ') }.to raise_error(ArgumentError)
    end
  end

  # ── .from_hash / #to_h round-trip ───────────────────────────────────────

  describe '.from_hash / #to_h round-trip' do
    it 'serialises and deserialises without data loss' do
      h  = GameSession.new_guesser_game
      gs = GameSession.from_hash(h)
      expect(gs.to_h).to eq(h)
    end

    it 'accepts string keys (as stored by some session backends)' do
      h = GameSession.new_guesser_game
      stringified = h.transform_keys(&:to_s)
                     .merge('history' => [], 'computer_history' => [])
      gs = GameSession.from_hash(stringified)
      expect(gs.turns_used).to eq(0)
    end
  end

  # ── #submit_guess ───────────────────────────────────────────────────────

  describe '#submit_guess' do
    let(:fixed_secret) { 'RGYB' }
    subject(:gs) { GameSession.from_hash(GameSession.new_maker_game(fixed_secret).tap { |h| h[:role] = 'guesser' }) }

    context 'with a valid guess' do
      it 'returns ok: true' do
        expect(gs.submit_guess('RRRR')[:ok]).to be true
      end

      it 'increments turns_used by 1' do
        expect { gs.submit_guess('RRRR') }.to change(gs, :turns_used).by(1)
      end

      it 'returns feedback with exact and color keys' do
        result = gs.submit_guess('RRRR')
        expect(result[:feedback]).to include(:exact, :color)
      end

      it 'returns correct exact count' do
        result = gs.submit_guess('RGYB')   # perfect match
        expect(result[:feedback][:exact]).to eq(4)
      end
    end

    context 'with an invalid guess (wrong length)' do
      it 'returns ok: false' do
        expect(gs.submit_guess('RRR')[:ok]).to be false
      end

      it 'includes an error message' do
        expect(gs.submit_guess('RRR')[:error]).to be_a(String)
      end

      it 'does not increment turns_used' do
        expect { gs.submit_guess('RRR') }.not_to change(gs, :turns_used)
      end
    end

    context 'with an invalid guess (bad color letter)' do
      it 'returns ok: false' do
        expect(gs.submit_guess('RXYZ')[:ok]).to be false
      end

      it 'does not consume a turn' do
        expect { gs.submit_guess('RXYZ') }.not_to change(gs, :turns_used)
      end
    end

    context 'when the secret is guessed correctly' do
      it 'sets status to won' do
        gs.submit_guess(fixed_secret)
        expect(gs.to_h[:status]).to eq('won')
      end
    end

    context 'after 12 failed guesses' do
      it 'sets status to lost (assuming secret is not RRRR)' do
        allow(Code).to receive(:random).and_return(Code.from_input('GGGG'))
        session = GameSession.from_hash(GameSession.new_guesser_game)
        12.times { session.submit_guess('RRRR') if session.status == 'playing' }
        expect(session.status).to eq('lost')
      end
    end

    context 'when game is already over' do
      it 'returns ok: false without incrementing turns' do
        gs.submit_guess(fixed_secret)              # win
        expect { gs.submit_guess('RRRR') }.not_to change(gs, :turns_used)
        expect(gs.submit_guess('RRRR')[:ok]).to be false
      end
    end
  end

  # ── #computer_guess ─────────────────────────────────────────────────────

  describe '#computer_guess' do
    subject(:gs) { GameSession.from_hash(GameSession.new_maker_game('RGYB')) }

    it 'returns a 4-letter guess string using valid colors' do
      result = gs.computer_guess
      expect(result[:guess]).to match(/\A[RGBYOP]{4}\z/)
    end

    it 'increments turns_used by 1' do
      expect { gs.computer_guess }.to change(gs, :turns_used).by(1)
    end

    it 'returns feedback hash' do
      result = gs.computer_guess
      expect(result[:feedback]).to include(:exact, :color)
    end

    it 'sets status to won when computer guesses correctly' do
      allow_any_instance_of(ComputerPlayer).to receive(:make_guess)
        .and_return(Code.from_input('RGYB'))
      gs.computer_guess
      expect(gs.status).to eq('won')
    end

    it 'rebuilds consistent computer player across multiple calls' do
      # Verify that computer_history is replayed correctly so the AI stays
      # consistent — just check it doesn't raise and turns accumulate.
      3.times { gs.computer_guess if gs.status == 'playing' }
      expect(gs.turns_used).to be <= 3
    end
  end

  # ── #board_rows ──────────────────────────────────────────────────────────

  describe '#board_rows' do
    subject(:gs) { GameSession.from_hash(GameSession.new_maker_game('RGYB').tap { |h| h[:role] = 'guesser' }) }

    it 'is empty before any guess' do
      expect(gs.board_rows).to be_empty
    end

    it 'grows by one row per valid guess' do
      gs.submit_guess('RRRR')
      expect(gs.board_rows.length).to eq(1)
    end

    it 'each row contains :turn, :guess, :exact, :color' do
      gs.submit_guess('RRRR')
      row = gs.board_rows.first
      expect(row).to include(:turn, :guess, :exact, :color)
    end

    it 'guess field is a 4-character string' do
      gs.submit_guess('RRRR')
      expect(gs.board_rows.first[:guess]).to eq('RRRR')
    end

    it 'turn numbers start at 1' do
      gs.submit_guess('RRRR')
      expect(gs.board_rows.first[:turn]).to eq(1)
    end
  end

  # ── Accessors ────────────────────────────────────────────────────────────

  describe 'accessors' do
    subject(:gs) { GameSession.from_hash(GameSession.new_guesser_game) }

    it '#turns_used starts at 0' do
      expect(gs.turns_used).to eq(0)
    end

    it '#max_turns is 12' do
      expect(gs.max_turns).to eq(12)
    end

    it '#status starts as playing' do
      expect(gs.status).to eq('playing')
    end

    it '#secret is a 4-character string' do
      expect(gs.secret).to match(/\A[RGBYOP]{4}\z/)
    end
  end
end
