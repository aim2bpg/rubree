require 'rails_helper'

RSpec.describe RegularExpression do
  describe 'validations' do
    context 'with valid expression and matching test string' do
      let(:regex) { described_class.new(expression: 'h(e)llo', test_string: 'hello') }

      it 'is valid' do
        expect(regex).to be_valid
      end

      it 'matches successfully' do
        regex.valid?
        expect(regex.match_success).to be true
      end

      it 'returns captures' do
        regex.valid?
        expect(regex.captures).to eq(['e'])
      end

      it 'returns match positions' do
        expect(regex.match_positions).to eq([{ start: 0, end: 5, index: 0 }])
      end
    end

    context 'with valid expression and no match' do
      let(:regex) { described_class.new(expression: 'foo', test_string: 'bar') }

      it 'is invalid' do
        expect(regex).not_to be_valid
      end

      it 'adds error for no match' do
        regex.valid?
        expect(regex.errors[:base]).to include('No match found...')
      end

      it 'returns empty captures' do
        regex.valid?
        expect(regex.captures).to eq([])
      end

      it 'returns no match positions' do
        expect(regex.match_positions).to eq([])
      end
    end

    context 'with invalid regex syntax' do
      let(:regex) { described_class.new(expression: '[a-z', test_string: 'abc') }

      it 'is invalid' do
        expect(regex).not_to be_valid
      end

      it 'adds error for invalid syntax' do
        regex.valid?
        expect(regex.errors[:base].first).to match(/Invalid regular expression syntax/)
      end

      it 'returns no match positions' do
        expect(regex.match_positions).to eq([])
      end
    end
  end

  describe '#named_captures' do
    context 'with named capture' do
      let(:regex) { described_class.new(expression: '(?<word>hello)', test_string: 'hello') }

      it 'returns named captures' do
        regex.valid?
        expect(regex.named_captures).to eq({ 'word' => 'hello' })
      end
    end

    context 'with no named capture' do
      let(:regex) { described_class.new(expression: '(hello)', test_string: 'hello') }

      it 'returns empty hash' do
        regex.valid?
        expect(regex.named_captures).to eq({})
      end
    end
  end

  describe '#diagram_svg' do
    let(:regex) { described_class.new(expression: 'a+', test_string: 'aaa') }

    before do
      allow(RegexpDiagram).to receive(:create_svg_from_regex).and_return('<svg><text>Diagram</text></svg>')
    end

    it 'returns sanitized SVG' do
      expect(regex.diagram_svg).to include('<svg>')
    end

    it 'is html_safe' do
      expect(regex.diagram_svg).to be_html_safe
    end
  end

  describe '#unready?' do
    it 'returns true if expression is blank' do
      expect(described_class.new(expression: '', test_string: 'test')).to be_unready
    end

    it 'returns true if test_string is blank' do
      expect(described_class.new(expression: 'abc', test_string: '')).to be_unready
    end

    it 'returns false if both are present' do
      expect(described_class.new(expression: 'abc', test_string: 'abc')).not_to be_unready
    end
  end
end
