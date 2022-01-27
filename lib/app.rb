class App
  include DatabaseLoader
  include RenderEngine

  PATHES = {
    root: '/',
    game: '/game',
    start: '/start',
    new_game: '/new_game',
    submit_answer: '/submit_answer',
    hint: '/hint',
    rules: '/rules'
  }.freeze
  PAGES = {
    menu: '/menu',
    game: '/game',
    rules: '/rules',
    game_over: '/game_over',
    error404: '/404'
  }.freeze
  ERROR_STATUS = 404

  attr_reader :helper

  def self.call(env)
    new(env).response.finish
  end

  def initialize(env)
    @request = Rack::Request.new(env)
    @helper = ViewHelper.new(@request)
  end

  def response
    return load_path if PATHES.value?(@request.path)

    render(PAGES[:error404], ERROR_STATUS)
  end

  def load_path
    case @request.path
    when *PATHES.values_at(:root, :game) then select_route
    when PATHES[:start] then start_game
    when PATHES[:new_game] then new_game
    when PATHES[:submit_answer] then submit_guess
    when PATHES[:hint] then take_hint
    when PATHES[:rules] then render(PAGES[:rules])
    end
  end

  def start_game
    return redirect(PATHES[:root]) unless @request.post?

    current_game = Codebreaker::Game.new
    current_game.create_game_params
    return redirect(PATHES[:root]) unless setup_user_params(current_game)

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
    render(PAGES[:game])
  end

  def take_hint
    return redirect(PATHES[:root]) unless game

    game_hint = game.give_hint
    game_hint ? helper.hints << game_hint : helper.flash.notice = I18n.t('flash.notice.no_hints')
    redirect(PAGES[:game])
  end

  def select_route
    return render(PAGES[:game_over]) if helper.status
    return render(PAGES[:game]) if game

    render(PAGES[:menu])
  end

  def submit_guess
    guess = @request.params['number']
    return redirect(PAGES[:game]) unless @request.post? && setup_game_data { game.setup_user_guess(guess) }

    handle_guess
    set_status
    save_game if helper.status == :won
    redirect(PAGES[:game])
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

  def save_game
    store_to_file([game.player, Time.now])
  end

  def new_game
    @request.session.clear
    redirect(PATHES[:root])
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

  def statistics
    Statistics.show
  end
end
