# spec/models/regular_expression_spec.rb
require 'rails_helper'

RSpec.describe RegularExpression do
  describe 'validations' do
    context 'when regular_expression and test_string are present and valid' do
      let(:regex) { described_class.new(regular_expression: 'h(e)llo', test_string: 'hello') }

      it 'is valid' do
        expect(regex).to be_valid
      end
    end

    context 'when regular_expression is blank' do
      let(:regex) { described_class.new(regular_expression: '', test_string: 'hello') }

      it 'is invalid' do
        expect(regex).not_to be_valid
        expect(regex.errors[:regular_expression]).to include("can't be blank")
      end

      it 'is unready' do
        expect(regex).to be_unready
      end
    end

    context 'when test_string is blank' do
      let(:regex) { described_class.new(regular_expression: 'abc', test_string: '') }

      it 'is invalid' do
        expect(regex).not_to be_valid
        expect(regex.errors[:test_string]).to include("can't be blank")
      end

      it 'is unready' do
        expect(regex).to be_unready
      end
    end

    context 'when regex syntax is invalid' do
      let(:regex) { described_class.new(regular_expression: '[a-z', test_string: 'abc') }

      it 'is invalid and adds base error' do
        expect(regex).not_to be_valid
        expect(regex.errors[:base].first).to match(/char-class|unterminated|invalid/i)
      end
    end

    context 'with valid regex options' do
      let(:regex) { described_class.new(regular_expression: '^hello', test_string: 'HeLLo', options: 'i') }

      it 'is valid' do
        expect(regex).to be_valid
      end
    end

    context 'with unsupported regex options' do
      let(:regex) { described_class.new(regular_expression: '^hello', test_string: 'hello', options: 'o') }

      it 'is valid but ignores unsupported options' do
        expect(regex).to be_valid
      end
    end
  end

  describe '#named_capture_groups' do
    context 'when named captures are present' do
      let(:regex) { described_class.new(regular_expression: '(?<word>hello)', test_string: 'hello world hello') }

      it 'returns the named captures correctly' do
        expect(regex.named_capture_groups).to eq([{ 'word' => 'hello' }, { 'word' => 'hello' }])
      end
    end

    context 'when no named captures are present' do
      let(:regex) { described_class.new(regular_expression: 'hello', test_string: 'hello world hello') }

      it 'returns an empty array' do
        expect(regex.named_capture_groups).to eq([])
      end
    end
  end

  describe '#capture_groups' do
    context 'when captures are present' do
      let(:regex) { described_class.new(regular_expression: '(hello)', test_string: 'hello world hello') }

      it 'returns the captures correctly' do
        expect(regex.capture_groups).to eq([['hello'], ['hello']])
      end
    end

    context 'when no captures are present' do
      let(:regex) { described_class.new(regular_expression: 'world', test_string: 'hello world hello') }

      it 'returns an empty array' do
        expect(regex.capture_groups).to eq([])
      end
    end
  end

  describe '#captures' do
    context 'when named captures are present' do
      let(:regex) { described_class.new(regular_expression: '(?<word>hello)', test_string: 'hello world hello') }

      it 'returns named captures' do
        expect(regex.named_capture_groups).to eq([{ 'word' => 'hello' }, { 'word' => 'hello' }])
      end
    end

    context 'when only regular captures are present' do
      let(:regex) { described_class.new(regular_expression: '(hello)', test_string: 'hello world hello') }

      it 'returns capture groups' do
        expect(regex.capture_groups).to eq([['hello'], ['hello']])
      end
    end

    context 'when no captures are present' do
      let(:regex) { described_class.new(regular_expression: 'world', test_string: 'hello hello') }

      it 'returns empty array' do
        expect(regex.capture_groups).to eq([])
      end
    end
  end

  describe '#match_spans' do
    context 'when matches are present' do
      let(:regex) { described_class.new(regular_expression: 'hello', test_string: 'hello world hello') }

      it 'returns correct match spans' do
        expect(regex.match_spans).to eq([
          { start: 0, end: 5, index: 0, invisible: true },
          { start: 12, end: 17, index: 1, invisible: true }
        ])
      end
    end

    context 'when no matches are present' do
      let(:regex) { described_class.new(regular_expression: 'goodbye', test_string: 'hello world hello') }

      it 'returns an empty array' do
        expect(regex.match_spans).to eq([])
      end
    end

    context 'when RegexpError occurs' do
      let(:regex) { described_class.new(regular_expression: '[a-z', test_string: 'abc') }

      it 'returns an empty array' do
        expect(regex.match_spans).to eq([])
      end
    end
  end

  describe '#diagram_svg' do
    context 'when rendering succeeds' do
      let(:regex) { described_class.new(regular_expression: 'hello', test_string: 'hello world') }

      it 'returns SVG string' do
        result = regex.diagram_svg
        expect(result).to be_a(String)
        expect(result).to include('<svg')
      end
    end

    context 'when regular_expression is invalid' do
      let(:regex) { described_class.new(regular_expression: '[a-z', test_string: 'abc') }

      it 'returns nil' do
        result = regex.diagram_svg
        expect(result).to be_nil
      end
    end
  end

  describe '#substitute' do
    context 'with valid substitution' do
      let(:regex) { described_class.new(regular_expression: 'hello', test_string: 'hello world', substitution: 'hi') }

      it 'returns highlighted substitution' do
        result = regex.substitute
        expect(result).to eq('<mark class="bg-green-300 p-0.5 rounded-xs text-green-900">hi</mark> world')
      end
    end

    context 'with invalid backreference in substitution' do
      let(:regex) { described_class.new(regular_expression: '(hello)', test_string: 'hello world', substitution: '\\9') }

      it 'returns original test string' do
        result = regex.substitute
        expect(result).to eq('hello world')
      end
    end

    context 'when substitution is nil' do
      let(:regex) { described_class.new(regular_expression: 'hello', test_string: 'hello world') }

      it 'returns nil' do
        result = regex.substitute
        expect(result).to be_nil
      end
    end
  end

  describe '#ruby_code' do
    context 'when substitution is provided' do
      let(:regex) { described_class.new(regular_expression: 'hello', test_string: 'hello world', substitution: 'hi') }

      it 'generates ruby code snippet' do
        result = regex.ruby_code
        expect(result).to be_a(String)
        expect(result).to include('substitution')
      end
    end

    context 'when substitution is not provided' do
      let(:regex) { described_class.new(regular_expression: 'hello', test_string: 'hello world') }

      it 'generates ruby code without substitution code' do
        result = regex.ruby_code
        expect(result).to be_a(String)
        expect(result).not_to include('substitute')
      end
    end
  end

  describe '#display_captures' do
    context 'when captures are present' do
      let(:regex) { described_class.new(regular_expression: '(hello) world (hello)', test_string: 'hello world hello') }

      it 'returns a list of highlighted captures' do
        result = regex.display_captures
        expect(result).to eq(
          ['<mark class="bg-green-300 p-0.5 rounded-xs text-green-900">hello</mark>',
           '<mark class="bg-green-300 p-0.5 rounded-xs text-green-900">hello</mark>']
        )
      end
    end

    context 'when no captures are present' do
      let(:regex) { described_class.new(regular_expression: 'world', test_string: 'hello world hello') }

      it 'returns an empty array' do
        result = regex.display_captures
        expect(result).to eq([])
      end
    end
  end
end
