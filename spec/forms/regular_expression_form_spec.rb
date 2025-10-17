require 'rails_helper'

RSpec.describe RegularExpressionForm do
  describe 'validations' do
    context 'when expression and test_string are present and valid' do
      let(:form) { described_class.new(expression: 'h(e)llo', test_string: 'hello') }

      it 'is valid' do
        expect(form).to be_valid
      end
    end

    context 'when expression is blank' do
      let(:form) { described_class.new(expression: '', test_string: 'hello') }

      it 'is invalid' do
        expect(form).not_to be_valid
        expect(form.errors[:expression]).to include("can't be blank")
      end

      it 'is unready' do
        expect(form).to be_unready
      end
    end

    context 'when test_string is blank' do
      let(:form) { described_class.new(expression: 'abc', test_string: '') }

      it 'is invalid' do
        expect(form).not_to be_valid
        expect(form.errors[:test_string]).to include("can't be blank")
      end

      it 'is unready' do
        expect(form).to be_unready
      end
    end

    context 'when regex syntax is invalid' do
      let(:form) { described_class.new(expression: '[a-z', test_string: 'abc') }

      it 'is invalid and adds base error' do
        expect(form).not_to be_valid
        expect(form.errors[:base].first).to match(/char-class|unterminated|invalid/i)
      end
    end

    context 'with valid regex options' do
      let(:form) { described_class.new(expression: '^hello', test_string: 'HeLLo', options: 'i') }

      it 'is valid' do
        expect(form).to be_valid
      end
    end

    context 'with unsupported regex options' do
      let(:form) { described_class.new(expression: '^hello', test_string: 'hello', options: 'o') }

      it 'is valid but ignores unsupported options' do
        expect(form).to be_valid
      end
    end

    context 'when multiple matches exist' do
      let(:form) { described_class.new(expression: 'h(e)llo', test_string: 'hello hello') }

      it 'is valid' do
        expect(form).to be_valid
      end
    end

    context 'when expression has named captures' do
      let(:form) { described_class.new(expression: '(?<word>hello)', test_string: 'hello') }

      it 'is valid' do
        expect(form).to be_valid
      end
    end

    context 'with substitution string present' do
      let(:form) { described_class.new(expression: 'hello', test_string: 'hello world', substitution: 'hi') }

      it 'is valid' do
        expect(form).to be_valid
      end
    end

    context 'with invalid substitution backreference' do
      let(:form) { described_class.new(expression: '(hello)', test_string: 'hello', substitution: '\\9') }

      it 'is still valid (validation does not check substitution syntax)' do
        expect(form).to be_valid
      end
    end
  end

  describe '#unready?' do
    it 'returns true if expression is blank' do
      form = described_class.new(expression: '', test_string: 'test')
      expect(form).to be_unready
    end

    it 'returns true if test_string is blank' do
      form = described_class.new(expression: 'abc', test_string: '')
      expect(form).to be_unready
    end

    it 'returns false if both are present' do
      form = described_class.new(expression: 'abc', test_string: 'abc')
      expect(form).not_to be_unready
    end
  end

  describe '#named_captures' do
    context 'when named captures are present' do
      let(:form) { described_class.new(expression: '(?<word>hello)', test_string: 'hello world hello') }

      it 'returns the named captures correctly' do
        result = form.named_captures
        expect(result).to eq([{ 'word' => 'hello' }, { 'word' => 'hello' }])
      end
    end

    context 'when no named captures are present' do
      let(:form) { described_class.new(expression: 'hello', test_string: 'hello world hello') }

      it 'returns an empty array' do
        result = form.named_captures
        expect(result).to eq([])
      end
    end

    context 'when named captures are empty' do
      let(:form) { described_class.new(expression: '(?<word>hello)', test_string: 'world') }

      it 'returns an empty array' do
        result = form.named_captures
        expect(result).to eq([])
      end
    end
  end

  describe '#captures' do
    context 'when captures are present' do
      let(:form) { described_class.new(expression: '(hello)', test_string: 'hello world hello') }

      it 'returns the captures correctly' do
        result = form.captures
        expect(result).to eq([['hello'], ['hello']])
      end
    end

    context 'when no captures are present' do
      let(:form) { described_class.new(expression: 'world', test_string: 'hello world hello') }

      it 'returns an empty array' do
        result = form.captures
        expect(result).to eq([])
      end
    end
  end

  describe '#match_positions' do
    context 'when match positions are available' do
      let(:form) { described_class.new(expression: 'hello', test_string: 'hello world hello') }

      it 'returns the correct match positions' do
        result = form.match_positions
        expect(result).to eq([
          { start: 0, end: 5, index: 0, invisible: true },
          { start: 12, end: 17, index: 1, invisible: true }
        ])
      end
    end

    context 'when no match positions are available' do
      let(:form) { described_class.new(expression: 'goodbye', test_string: 'hello world hello') }

      it 'returns an empty array' do
        result = form.match_positions
        expect(result).to eq([])
      end
    end

    context 'when regexp raises RegexpError' do
      let(:form) { described_class.new(expression: '[a-z', test_string: 'abc') }

      it 'returns an empty array' do
        result = form.match_positions
        expect(result).to eq([])
      end
    end
  end

  describe '#diagram_svg' do
    context 'when diagram rendering is successful' do
      let(:form) { described_class.new(expression: 'hello', test_string: 'hello world') }

      it 'returns a valid SVG' do
        result = form.diagram_svg
        expect(result).to be_a(String)  # SVG is a string
        expect(result).to include('<svg')  # check if the result contains SVG tags
      end
    end

    context 'when diagram rendering fails due to invalid regex' do
      let(:form) { described_class.new(expression: '[a-z', test_string: 'abc') }

      it 'returns nil' do
        result = form.diagram_svg
        expect(result).to be_nil
      end
    end
  end

  describe '#perform_substitution' do
    context 'when substitution is performed successfully' do
      let(:form) { described_class.new(expression: 'hello', test_string: 'hello world', substitution: 'hi') }

      it 'returns the substituted result' do
        result = form.perform_substitution
        expect(result).to eq('<mark class="bg-green-300 p-0.5 rounded-xs text-green-900">hi</mark> world')
      end
    end

    context 'when substitution is invalid (e.g., incorrect backreference)' do
      let(:form) { described_class.new(expression: '(hello)', test_string: 'hello world', substitution: '\\9') }

      it 'performs substitution using the backreference as a string' do
        result = form.perform_substitution
        expect(result).to eq('hello world')
      end
    end

    context 'when substitution is not present' do
      let(:form) { described_class.new(expression: 'hello', test_string: 'hello world') }

      it 'returns nil' do
        result = form.perform_substitution
        expect(result).to be_nil
      end
    end
  end

  describe '#ruby_code_snippet' do
    context 'when ruby code snippet is generated' do
      let(:form) { described_class.new(expression: 'hello', test_string: 'hello world', substitution: 'hi') }

      it 'returns a valid Ruby code snippet' do
        result = form.ruby_code_snippet
        expect(result).to be_a(String)
        expect(result).to include('substitution')  # Check that substitution code is included
      end
    end

    context 'when no substitution is provided' do
      let(:form) { described_class.new(expression: 'hello', test_string: 'hello world') }

      it 'returns a valid Ruby code snippet without substitution' do
        result = form.ruby_code_snippet
        expect(result).to be_a(String)
        expect(result).not_to include('substitute')  # No substitution code
      end
    end
  end

  describe '#display_captures' do
    context 'when named captures are present' do
      let(:form) { described_class.new(expression: '(?<word>hello)', test_string: 'hello world hello') }

      it 'returns the named captures correctly' do
        result = form.display_captures
        expect(result).to eq([{ 'word' => 'hello' }, { 'word' => 'hello' }])
      end
    end

    context 'when no named captures are present, but regular captures exist' do
      let(:form) { described_class.new(expression: '(hello)', test_string: 'hello world hello') }

      it 'returns regular captures' do
        result = form.display_captures
        expect(result).to eq([['hello'], ['hello']])
      end
    end

    context 'when neither named captures nor regular captures are present' do
      let(:form) { described_class.new(expression: 'world', test_string: 'hello world hello') }

      it 'returns an empty array' do
        result = form.display_captures
        expect(result).to eq([])
      end
    end
  end
end
