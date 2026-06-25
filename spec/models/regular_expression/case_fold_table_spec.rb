require 'rails_helper'

RSpec.describe RegularExpression::CaseFoldTable do
  describe '.single_char_variants' do
    it 'returns uppercase and lowercase for a basic ASCII letter' do
      expect(described_class.single_char_variants('a')).to contain_exactly('A', 'a')
    end

    it 'returns single-char equivalents for ß (excludes multi-char "ss" fold)' do
      result = described_class.single_char_variants('ß')
      expect(result).to include('ß', 'ẞ')
      expect(result.all? { |c| c.length == 1 }).to be true
    end

    it 'returns only the char itself for digits (no case variants)' do
      expect(described_class.single_char_variants('1')).to eq(['1'])
    end
  end

  describe '.sequence_single_char_variants' do
    it 'returns single chars that fold to the same key as "ss" (e.g. ß, ẞ)' do
      result = described_class.sequence_single_char_variants('ss')
      expect(result).to include('ß', 'ẞ')
      expect(result.all? { |c| c.length == 1 }).to be true
    end

    it 'returns empty for a single-char input' do
      expect(described_class.sequence_single_char_variants('a')).to eq([])
    end

    it 'returns ligature variants for "st" (ﬆ, ﬅ)' do
      result = described_class.sequence_single_char_variants('st')
      expect(result).to include('ﬆ', 'ﬅ')
    end
  end

  describe '.single_char_variants_for_fold' do
    it 'returns chars that fold to "ss" key' do
      result = described_class.single_char_variants_for_fold('ss')
      expect(result).to include('ß', 'ẞ')
    end

    it 'returns empty for a fold key with no equivalents' do
      expect(described_class.single_char_variants_for_fold('123nonexistent')).to eq([])
    end
  end
end
