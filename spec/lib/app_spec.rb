RSpec.describe App do
  let(:app) { Rack::Builder.parse_file('config.ru').first }
  let(:game) { Codebreaker::Game.new }
  let(:valid_name) { FFaker::Name.first_name }
  let(:valid_level) { Codebreaker::Player::DIFFICULTY_HASH.keys.first.to_s }
  let(:pathes) { App::PATHES }

  describe 'common route rules' do
    context 'when GET to root page' do
      let(:ok_status) { 200 }

      it 'returns OK status' do
        get pathes[:root]
        expect(last_response.status).to eq(ok_status)
      end
    end

    context 'when no game was started' do
      let(:label) { I18n.t('menu.player_name') }

      it 'renders "menu"' do
        get pathes[:game]
        expect(last_response.body).to include(label)
      end

      it 'redirects to root page' do
        get pathes[:hint]
        expect(last_response.location).to eq(pathes[:root])
      end
    end

    context 'when push new game button' do
      before { env 'rack.session', game: game }

      it 'clear session ' do
        get pathes[:new_game]
        expect(last_request.session).to be_empty
      end
    end

    context 'when not POST request' do
      it 'redirects to root page' do
        get pathes[:start]
        expect(last_response.location).to eq(pathes[:root])
      end
    end

    context 'when path not allowed' do
      let(:pathes) { Array.new(5) { "/#{FFaker::Lorem.word}" } }
      let(:no_page_status) { App::ERROR_STATUS }

      it 'returns 404 status' do
        pathes.each do |path|
          get path
          expect(last_response.status).to eq(no_page_status)
        end
      end
    end

    context 'when path /rules' do
      it 'returns rules page' do
        get pathes[:rules]
        expect(last_response.body).to include(I18n.t('rules').first)
      end
    end
  end

  describe 'press start the game button' do
    let(:flash) { last_request.env['x-rack.flash'] }
    let(:player) { last_request.session[:game].player }

    context 'when player name is invalid' do
      let(:wrong_name) { FFaker::Name.first_name.slice(1, 2) }

      before { post pathes[:start], player_name: wrong_name, level: valid_level }

      it 'redirects to home page' do
        expect(last_response.location).to eq(pathes[:root])
      end

      it 'sets specific error to flash hash' do
        expect(flash.error).to eq(Codebreaker::Validations::NAME_ERROR)
      end

      it 'displays error after redirect' do
        follow_redirect!
        expect(last_response.body).to include(Codebreaker::Validations::NAME_ERROR)
      end
    end

    context 'when difficulty level is invalid' do
      let(:wrong_level) { FFaker::Lorem.word }

      before { post pathes[:start], player_name: valid_name, level: wrong_level }

      it 'redirects to home page' do
        expect(last_response.location).to eq(pathes[:root])
      end

      it 'sets specific error to flash hash' do
        expect(flash.error).to eq(Codebreaker::Validations::DIFFICULTY_ERROR)
      end

      it 'displays error after redirect' do
        follow_redirect!
        expect(last_response.body).to include(Codebreaker::Validations::DIFFICULTY_ERROR)
      end
    end

    context 'when player name and level is correct' do
      before { post pathes[:start], player_name: valid_name, level: valid_level }

      it 'creates game instanse and store it to session cookie' do
        expect(last_request.session[:game]).to be_a(Codebreaker::Game)
      end

      it 'creates game with issued name' do
        expect(player.name).to eq(valid_name)
      end

      it 'creates game with issued difficulty level' do
        expect(player.difficulty).to eq(valid_level)
      end
    end
  end

  describe 'game process' do
    let(:secret_code) do
      Array.new(Codebreaker::Validations::CODE_SIZE) do
        rand(Codebreaker::Validations::MIN_DIGIT..Codebreaker::Validations::MAX_DIGIT)
      end
    end
    let(:wrong_guess) { secret_code.map { |n| n < 6 ? n + 1 : n }.join }
    let(:invalid_guess) { secret_code.join * rand(2..3) }
    let(:redirect_status) { 302 }

    before do
      game.create_game_params
      game.setup_name(valid_name)
      game.setup_difficulty(valid_level.to_sym)
      env 'rack.session', game: game, hints: []
    end

    it 'displays current player name' do
      get pathes[:game]
      expect(last_response.body).to include(valid_name)
    end

    context 'when press hint button' do
      it 'add  hint to hints hash in session' do
        get pathes[:hint]
        expect(last_request.session[:hints].size).to eq(1)
      end
    end

    context 'when no more hints left' do
      before { 2.times { game.give_hint } }

      it 'show flash notice "no hints"' do
        get pathes[:hint]
        follow_redirect!
        expect(last_response.body).to include(I18n.t('flash.notice.no_hints'))
      end
    end

    context 'when guess format is invalid' do
      before { post pathes[:submit_answer], number: invalid_guess }

      it 'sets specific error to flash hash' do
        expect(last_request.env['x-rack.flash'].error).to eq(Codebreaker::Validations::GUESS_ERROR)
      end

      it 'displays error after redirect' do
        follow_redirect!
        expect(last_response.body).to include(Codebreaker::Validations::GUESS_ERROR)
      end
    end

    context 'when guess format is valid' do
      before do
        game.instance_variable_set(:@secret_code, secret_code)
        post pathes[:submit_answer], number: wrong_guess
      end

      it 'stores player`s input to session cookie' do
        expect(last_request.session[:player_guess]).to eq(wrong_guess)
      end

      it 'stores to session result of checking guess' do
        expect(last_request.session[:result_check]).to eq(game.check_user_guess)
      end
    end

    context 'when player lose' do
      let(:attempts_total) { Codebreaker::Player::DIFFICULTY_HASH[:easy][:attempts] }

      before do
        game.instance_variable_set(:@secret_code, secret_code)
        game.setup_user_guess(wrong_guess)
        (attempts_total - 1).times { game.check_user_guess }
        post pathes[:submit_answer], number: wrong_guess
      end

      it 'store :lose status to session' do
        expect(last_request.session[:status]).to eq(:lose)
      end

      it 'redirects to game_over page' do
        expect(last_response.status).to eq(redirect_status)
      end
    end

    context 'when player won' do
      before do
        game.instance_variable_set(:@secret_code, secret_code)
        post pathes[:submit_answer], number: secret_code.join
      end

      it 'store :won status to session' do
        expect(last_request.session[:status]).to eq(:won)
      end

      it 'redirects to game_over page' do
        expect(last_response.status).to eq(redirect_status)
      end
    end
  end
end
