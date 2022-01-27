module GameHelper
  def setup_game_data
    yield
  rescue Codebreaker::ValidationError => e
    helper.flash.error = e.message
    false
  end

  def setup_player_name(codegame, value)
    setup_game_data do
      codegame.setup_name(value)
    end
  end

  def setup_difficulty_level(codegame, value)
    setup_game_data do
      codegame.setup_difficulty(value)
    end
  end

  def setup_guess(codegame, value)
    setup_game_data do
      codegame.setup_user_guess(value)
    end
  end
end
