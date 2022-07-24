# frozen_string_literal: true

RSpec.describe ViewHelper do
  let(:app) { Rack::Builder.parse_file('config.ru').first }
  let(:game) { Codebreaker::Game.new }
  let(:valid_name) { 'Heizenberg' }
  let(:valid_level) { Codebreaker::Player::DIFFICULTY_HASH.keys.first }
  let(:attempts_total) { Codebreaker::Player::DIFFICULTY_HASH[:easy][:attempts] }
  let(:hints_total) { Codebreaker::Player::DIFFICULTY_HASH[:easy][:hints] }
  let(:secret_code) { [1, 2, 3, 4] }
  let(:wrong_guess) { '1121' }
  let(:marks) { ['btn marks btn-success', 'btn marks btn-primary', 'btn marks btn-danger'] }

  before do
    game.create_game_params
    game.setup_name(valid_name)
    game.setup_difficulty(valid_level)
    game.instance_variable_set(:@secret_code, secret_code)
    env 'rack.session', game: game
  end

  it 'displays current difficulty level' do
    get '/game'
    expect(last_response.body).to include(valid_level.to_s.capitalize)
  end

  it 'displays current attempts count' do
    get '/game'
    expect(last_response.body).to include(attempts_total.to_s)
  end

  it 'displays current hints count' do
    get '/game'
    expect(last_response.body).to include(hints_total.to_s)
  end

  context 'with wrong guess' do
    it 'displays result of guess with specific colors' do
      post '/submit_answer', number: wrong_guess
      follow_redirect!
      expect(last_response.body).to include(*marks)
    end
  end

  context 'when player lose' do
    before do
      game.setup_user_guess(wrong_guess)
      (attempts_total - 1).times { game.check_user_guess }
      post '/submit_answer', number: wrong_guess
    end

    it 'renders game_over page after redirect with "lose message"' do
      follow_redirect!
      expect(last_response.body).to include(I18n.t('game_over.lose', name: game.player.name))
    end
  end

  context 'when player won' do
    let(:file_path) { 'spec/fixtures/test.yml' }

    before do
      stub_const('DatabaseLoader::DATA_FILE', file_path)
      File.new(file_path, 'w')
      post '/submit_answer', number: secret_code.join
    end

    after { File.delete(file_path) }

    it 'renders game_over page after redirect with "won message"' do
      follow_redirect!
      expect(last_response.body).to include(I18n.t('game_over.won', name: game.player.name))
    end
  end
end
