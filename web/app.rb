require 'sinatra/base'
require_relative 'game_session'

class MastermindApp < Sinatra::Base
  set :root,          File.expand_path('..', __dir__)
  set :views,         File.join(settings.root, 'web', 'views')
  set :public_folder, File.join(settings.root, 'public')
  set :erb, escape_html: true

  configure :test do
    disable :protection
  end

  use Rack::Session::Cookie,
      key:       'mastermind.session',
      secret:    ENV.fetch('SESSION_SECRET', 'dev-secret-replace-this-with-a-long-random-string-in-production!!'),
      same_site: :lax

  # ── Simple flash ────────────────────────────────────────────────────────

  helpers do
    def flash_error(msg)
      session[:flash_error] = msg
    end

    def flash_error!
      msg = session.delete(:flash_error)
      msg
    end

    def current_game
      return nil unless session[:game]
      GameSession.from_hash(session[:game])
    end

    def save_game(gs)
      session[:game] = gs.to_h
    end
  end

  # ── Routes ─────────────────────────────────────────────────────────────

  get '/' do
    session.delete(:game)
    @error = flash_error!
    erb :index
  end

  post '/game/start' do
    role = params[:role]

    if role == '1'
      session[:game] = GameSession.new_guesser_game
      redirect '/game'
    elsif role == '2'
      begin
        session[:game] = GameSession.new_maker_game(params[:secret].to_s.strip)
        redirect '/game'
      rescue ArgumentError => e
        flash_error(e.message)
        redirect '/'
      end
    else
      flash_error('Invalid role selection.')
      redirect '/'
    end
  end

  get '/game' do
    gs = current_game
    redirect '/' unless gs
    @game = gs
    erb :game
  end

  post '/game/guess' do
    gs = current_game
    redirect '/' unless gs

    gs.submit_guess(params[:guess].to_s.strip.upcase)
    save_game(gs)
    redirect '/game'
  end

  post '/game/computer' do
    gs = current_game
    redirect '/' unless gs

    gs.computer_guess
    save_game(gs)
    redirect '/game'
  end

  post '/game/reset' do
    session.clear
    redirect '/'
  end

  run! if app_file == $0
end
