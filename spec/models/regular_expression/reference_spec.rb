require 'rails_helper'

RSpec.describe RegularExpression::Reference do
  describe '.sections' do
    it 'returns an array of sections with title and items' do
      sections = described_class.sections
      expect(sections).to be_an(Array)
      expect(sections).not_to be_empty

      section = sections.first
      expect(section).to include(:title, :items)
      expect(section[:items]).to be_an(Array)
      item = section[:items].first
      expect(item).to be_a(Array)
      expect(item.size).to eq(2) # [code, description]
    end
  end

  describe '.options' do
    it 'returns an array of flag/label pairs including common flags' do
      opts = described_class.options
      expect(opts).to be_an(Array)
      flags = opts.map(&:first)
      expect(flags).to include('i', 'm', 'x')
      expect(opts.first.size).to eq(2)
    end
  end
end
