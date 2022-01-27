RSpec.describe Statistics do
  let(:file_path) { 'spec/fixtures/test.yml' }
  let(:names) { %w[Walter Jessy Gustavo] }
  let(:fake_data) do
    players = []
    names.map do |name|
      3.times do |i|
        player = Codebreaker::Player.new
        player.name = name + i.to_s
        player.get_difficulty(Statistics::LEVELS.slice(i))
        players << [player, Time.now]
      end
    end
    players
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
      expect(described_class.show.first[0].name).to eql('Walter0')
    end
  end

  context 'with easy level at last position' do
    it 'returns sorted data' do
      expect(described_class.show.last[0].name).to eql('Gustavo2')
    end
  end
end
