# frozen_string_literal: true

class Statistics
  extend DatabaseLoader
  LEVELS = Codebreaker::Player::DIFFICULTY_HASH.keys.map(&:to_s).reverse.freeze

  def self.show
    data = load_from_file
    return [] unless data

    data.sort_by do |object|
      [LEVELS.index(object[0].difficulty), object[0].attempts_used, object[0].hints_used, object[1]]
    end
  end
end
