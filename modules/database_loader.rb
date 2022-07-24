# frozen_string_literal: true

module DatabaseLoader
  DATA_FILE = File.expand_path('../db/db.yml', __dir__).freeze
  DIR_NAME = 'db'

  def load_from_file
    YAML.load_stream(File.read(DATA_FILE)) if File.exist?(DATA_FILE)
  end

  def store_to_file(game)
    Dir.mkdir(DIR_NAME) unless Dir.exist?(DIR_NAME)
    File.open(DATA_FILE, 'a') { |file| file.write(game.to_yaml) }
  end
end
