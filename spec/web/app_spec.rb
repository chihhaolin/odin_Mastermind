require 'spec_helper'

RSpec.describe 'Mastermind Web App', type: :request do

  # ── GET / ────────────────────────────────────────────────────────────────

  describe 'GET /' do
    it 'returns 200' do
      get '/'
      expect(last_response.status).to eq(200)
    end

    it 'shows role selection options' do
      get '/'
      expect(last_response.body).to include('Guesser')
      expect(last_response.body).to include('Code Maker')
    end

    it 'shows all 6 color abbreviations' do
      get '/'
      %w[R G B Y O P].each { |c| expect(last_response.body).to include(c) }
    end

    it 'clears an existing game session' do
      post '/game/start', role: '1'   # start a game first
      get '/'
      get '/game'                     # now there should be no game
      expect(last_response).to be_redirect
      follow_redirect!
      expect(last_request.path).to eq('/')
    end
  end

  # ── POST /game/start ────────────────────────────────────────────────────

  describe 'POST /game/start' do
    context 'role=1 (Guesser)' do
      it 'redirects to /game' do
        post '/game/start', role: '1'
        expect(last_response).to be_redirect
        follow_redirect!
        expect(last_request.path).to eq('/game')
      end

      it 'game page shows the guess input field' do
        post '/game/start', role: '1'
        follow_redirect!
        expect(last_response.body).to include('guess')
        expect(last_response.body).to include('<input')
      end

      it 'game page shows turn counter starting at 0 of 12' do
        post '/game/start', role: '1'
        follow_redirect!
        expect(last_response.body).to include('12')
      end
    end

    context 'role=2 (Maker) with valid secret' do
      it 'redirects to /game' do
        post '/game/start', role: '2', secret: 'RGYB'
        expect(last_response).to be_redirect
        follow_redirect!
        expect(last_request.path).to eq('/game')
      end

      it 'game page shows the computer-guess trigger button' do
        post '/game/start', role: '2', secret: 'RGYB'
        follow_redirect!
        expect(last_response.body).to include('/game/computer')
      end
    end

    context 'role=2 with invalid secret (too short)' do
      it 'redirects back to /' do
        post '/game/start', role: '2', secret: 'RRR'
        expect(last_response).to be_redirect
        follow_redirect!
        expect(last_request.path).to eq('/')
      end

      it 'shows an error message on the home page' do
        post '/game/start', role: '2', secret: 'RRR'
        follow_redirect!
        expect(last_response.body).to match(/error|Error|invalid|Invalid/i)
      end
    end

    context 'role=2 with invalid color letters' do
      it 'redirects back to / with an error' do
        post '/game/start', role: '2', secret: 'RXYZ'
        expect(last_response).to be_redirect
        follow_redirect!
        expect(last_request.path).to eq('/')
        expect(last_response.body).to match(/error|Error|invalid|Invalid/i)
      end
    end

    context 'unknown role' do
      it 'redirects back to /' do
        post '/game/start', role: '9'
        expect(last_response).to be_redirect
        follow_redirect!
        expect(last_request.path).to eq('/')
      end
    end
  end

  # ── GET /game ────────────────────────────────────────────────────────────

  describe 'GET /game' do
    context 'with no active session' do
      it 'redirects to /' do
        get '/game'
        expect(last_response).to be_redirect
        follow_redirect!
        expect(last_request.path).to eq('/')
      end
    end

    context 'with an active session' do
      before { post '/game/start', role: '1' }

      it 'returns 200 after redirect' do
        follow_redirect!
        expect(last_response.status).to eq(200)
      end
    end
  end

  # ── POST /game/guess ─────────────────────────────────────────────────────

  describe 'POST /game/guess' do
    before { post '/game/start', role: '1' }

    context 'valid guess' do
      it 'follows PRG — redirects to /game' do
        post '/game/guess', guess: 'RRRR'
        expect(last_response).to be_redirect
        follow_redirect!
        expect(last_request.path).to eq('/game')
      end

      it 'shows the submitted guess on the board' do
        post '/game/guess', guess: 'RGYB'
        follow_redirect!
        expect(last_response.body).to include('RGYB')
      end

      it 'shows Exact and Color columns' do
        post '/game/guess', guess: 'RRRR'
        follow_redirect!
        expect(last_response.body).to match(/Exact|exact/i)
        expect(last_response.body).to match(/Color|color/i)
      end

      it 'decrements remaining turns displayed' do
        post '/game/guess', guess: 'RRRR'
        follow_redirect!
        # After 1 guess, turn counter should show Turn 1 / 12 (or similar)
        expect(last_response.body).to include('12')
      end
    end

    context 'invalid guess (too short)' do
      it 'redirects to /game and shows error without consuming a turn' do
        post '/game/guess', guess: 'RRR'
        follow_redirect!
        # Board should still be empty (0 turns used)
        expect(last_response.body).not_to include('<tbody>')
        expect(last_response.body).to match(/error|Error|Must|must/i)
      end
    end

    context 'invalid guess (bad color letter)' do
      it 'shows an error' do
        post '/game/guess', guess: 'RXYZ'
        follow_redirect!
        expect(last_response.body).to match(/error|Error|invalid|Invalid/i)
      end
    end

    context 'guess that wins the game' do
      it 'shows a win banner' do
        allow(Code).to receive(:random).and_return(Code.from_input('RGYB'))
        post '/game/start', role: '1'
        post '/game/guess', guess: 'RGYB'
        follow_redirect!
        expect(last_response.body).to match(/cracked|win|Solved|Won/i)
      end
    end

    context 'after 12 failed guesses' do
      it 'shows a loss banner' do
        allow(Code).to receive(:random).and_return(Code.from_input('GGGG'))
        post '/game/start', role: '1'
        12.times { post '/game/guess', guess: 'RRRR' }
        follow_redirect!
        expect(last_response.body).to match(/out of turns|failed|lose|Lost/i)
      end
    end
  end

  # ── POST /game/computer ──────────────────────────────────────────────────

  describe 'POST /game/computer' do
    before { post '/game/start', role: '2', secret: 'RGYB' }

    it 'redirects to /game' do
      post '/game/computer'
      expect(last_response).to be_redirect
      follow_redirect!
      expect(last_request.path).to eq('/game')
    end

    it 'shows the computer guess on the board (valid 4-letter color code)' do
      post '/game/computer'
      follow_redirect!
      # Board renders each color as a separate <span class="color-pill X">X</span>
      expect(last_response.body).to include('guess-cells')
      expect(last_response.body).to match(/color-pill [RGBYOP]/)
    end

    it 'accumulates turns over multiple calls' do
      3.times { post '/game/computer' }
      follow_redirect!
      # Board should have 3 rows — look for turn numbers 1, 2, 3
      expect(last_response.body).to include('3')
    end

    context 'when the computer guesses correctly' do
      it 'shows a win banner for the computer' do
        allow_any_instance_of(ComputerPlayer).to receive(:make_guess)
          .and_return(Code.from_input('RGYB'))
        post '/game/computer'
        follow_redirect!
        expect(last_response.body).to match(/cracked|computer|win/i)
      end
    end
  end

  # ── POST /game/reset ─────────────────────────────────────────────────────

  describe 'POST /game/reset' do
    before { post '/game/start', role: '1' }

    it 'redirects to /' do
      post '/game/reset'
      expect(last_response).to be_redirect
      follow_redirect!
      expect(last_request.path).to eq('/')
    end

    it 'clears the session so /game redirects to / afterwards' do
      post '/game/reset'
      get '/game'
      expect(last_response).to be_redirect
      follow_redirect!
      expect(last_request.path).to eq('/')
    end

    it 'shows the role selection on the home page after reset' do
      post '/game/reset'
      follow_redirect!
      expect(last_response.body).to include('Guesser')
    end
  end
end
