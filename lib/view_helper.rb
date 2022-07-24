# frozen_string_literal: true

class ViewHelper
  def initialize(request)
    @request = request
  end

  def player
    @request.session[:game].player
  end

  def flash
    @request.env['x-rack.flash']
  end

  def hints
    @request.session[:hints] || []
  end

  def result_check
    @request.session[:result_check] || []
  end

  def player_guess
    @request.session[:player_guess]
  end

  def status
    @request.session[:status]
  end

  def levels
    Codebreaker::Player::DIFFICULTY_HASH
  end

  def game_level
    player.difficulty.capitalize
  end

  def attempts_left
    player.attempts - player.attempts_used
  end

  def hints_left
    player.hints - player.hints_used
  end

  def game_over_message
    case status
    when :won then I18n.t('game_over.won', name: player.name)
    when :lose then I18n.t('game_over.lose', name: player.name)
    end
  end

  def button_class(value)
    case value
    when Codebreaker::CodeChecker::PLUS then 'btn-success'
    when Codebreaker::CodeChecker::MINUS then 'btn-primary'
    else 'btn-danger'
    end
  end

  def statistics
    Statistics.show
  end
end
