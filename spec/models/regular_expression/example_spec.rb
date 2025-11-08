require 'rails_helper'

RSpec.describe RegularExpression::Example do
  describe '.categories' do
    it 'returns a hash of categories with examples' do
      cats = described_class.categories
      expect(cats).to be_a(Hash)
      expect(cats).not_to be_empty

      key, data = cats.first
      expect(data).to include(:short, :description, :examples)
      expect(data[:examples]).to be_an(Array)
      ex = data[:examples].first
      expect(ex).to be_a(Hash)
      expect(ex).to include(:pattern, :test)
    end

    it 'provides example_categories as an alias' do
      expect(described_class).to respond_to(:example_categories)
      expect(described_class.example_categories).to eq(described_class.categories)
    end
  end
end
