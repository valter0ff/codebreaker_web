RSpec.describe Statistics do
  let(:file_path) { 'spec/fixtures/test.yml' }
  let(:levels) { Statistics::LEVELS }
  let(:players_count) { 20 }
  let(:names) { Array.new(players_count) { FFaker::Name.first_name } }
  let(:fake_data) do
    names.map do |name|
      player = Codebreaker::Player.new
      player.name = name
      player.get_difficulty(levels.sample)
      [player, Time.now]
    end
  end

  before do
    stub_const('DatabaseLoader::DATA_FILE', file_path)
    fake_data.each do |obj|
      File.open(file_path, 'a') { |file| file.write(obj.to_yaml) }
    end
  end

  after { File.delete(file_path) }

  context 'with hell level at first position' do
    it 'returns sorted data ' do
      expect(described_class.show.first[0].difficulty).to eq(levels.first)
    end
  end

  context 'with easy level at last position' do
    it 'returns sorted data' do
      expect(described_class.show.last[0].difficulty).to eq(levels.last)
    end
  end
end
