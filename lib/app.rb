class App
  include RenderEngine

  attr_reader :helper

  def self.call(env)
    new(env).response.finish
  end

  def initialize(env)
    @request = Rack::Request.new(env)
    @helper = ViewHelper.new(@request)
  end

  def response
    case @request.path
    when '/', '/game' then select_route
    when '/start' then start_game
    when '/new_game' then new_game
    when '/submit_answer' then submit_guess
    when '/hint' then take_hint
    when '/rules' then render('rules')
    else render('404', 404)
    end
  end

  def start_game
    return redirect('/') unless @request.post?

    current_game = Codebreaker::Game.new
    current_game.create_game_params
    return redirect('/') unless setup_user_params(current_game)

    setup_session(current_game)
  end

  def setup_user_params(game_instance)
    name = setup_game_data { game_instance.setup_name(@request.params['player_name']) }
    level = setup_game_data { game_instance.setup_difficulty(@request.params['level']) }
    name && level
  end

  def setup_session(game_instance)
    @request.session[:game] = game_instance
    @request.session[:hints] = []
    render('game')
  end

  def take_hint
    return redirect('/') unless game

    game_hint = game.give_hint
    game_hint ? helper.hints << game_hint : helper.flash.notice = I18n.t('flash.notice.no_hints')
    redirect('/game')
  end

  def select_route
    return render('game_over') if helper.status
    return render('game') if game

    render('menu')
  end

  def submit_guess
    guess = @request.params['number']
    return redirect('/game') unless @request.post? && setup_game_data { game.setup_user_guess(guess) }

    handle_guess
    set_status
    redirect('/game')
  end

  def handle_guess
    @request.session[:player_guess] = @request.params['number']
    @request.session[:result_check] = game.check_user_guess
  end

  def set_status
    @request.session[:status] = if helper.player_guess == game.secret_code.join then :won
                                elsif helper.attempts_left.zero? then :lose
                                end
  end

  def new_game
    @request.session.clear
    redirect('/')
  end

  def game
    @request.session[:game]
  end

  def setup_game_data
    yield
  rescue Codebreaker::ValidationError => e
    helper.flash.error = e.message
    false
  end
end
