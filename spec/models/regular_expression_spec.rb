require 'rails_helper'

RSpec.describe RegularExpression do
  describe 'validations' do
    context 'with valid expression and matching test string' do
      let(:regex) { described_class.new(
        expression: 'h(e)llo',
        test_string: 'hello'
      ) }

      it 'is valid' do
        expect(regex).to be_valid
      end

      it 'matches successfully and returns match positions' do
        regex.valid?
        expect(regex.match_positions).to eq(
          [{ start: 0, end: 5, index: 0, invisible: true }]
        )
      end

      it 'returns captures' do
        regex.valid?
        expect(regex.captures).to eq(
          [['e']]
        )
      end
    end

    context 'with multiple matches' do
      let(:regex) { described_class.new(
        expression: 'h(e)llo',
        test_string: 'hello hello'
      ) }

      it 'is valid' do
        expect(regex).to be_valid
      end

      it 'matches multiple times' do
        regex.valid?
        expect(regex.match_positions).to eq(
          [{ start: 0, end: 5, index: 0, invisible: true },
           { start: 6, end: 11, index: 1, invisible: true }]
        )
      end

      it 'returns multiple capture groups' do
        regex.valid?
        expect(regex.captures).to eq(
          [['e'], ['e']]
        )
      end

      it 'returns display_captures as unnamed captures' do
        regex.valid?
        expect(regex.display_captures).to eq(
          [['e'], ['e']]
        )
      end
    end

    context 'with named captures and multiple matches' do
      let(:regex) { described_class.new(
        expression: '(?<word>hello)',
        test_string: 'hello hello'
      ) }

      it 'returns named captures for each match' do
        regex.valid?
        expect(regex.named_captures).to eq(
          [{ 'word' => 'hello' }, { 'word' => 'hello' }]
        )
      end

      it 'returns display_captures as named captures' do
        regex.valid?
        expect(regex.display_captures).to eq(
          [{ 'word' => 'hello' }, { 'word' => 'hello' }]
        )
      end
    end

    context 'when both named and unnamed captures exist' do
      let(:regex) { described_class.new(
        expression: '(?<name>hello)(world)',
        test_string: 'helloworld helloworld'
      ) }

      it 'returns named captures only' do
        regex.valid?
        expect(regex.display_captures).to eq(
          [{ 'name' => 'hello' }, { 'name' => 'hello' }]
        )
      end
    end

    context 'with valid expression and no match' do
      let(:regex) { described_class.new(
        expression: 'foo',
        test_string: 'bar'
      ) }

      it 'is valid' do
        expect(regex).to be_valid
      end

      it 'has no match success' do
        regex.valid?
        expect(regex.match_success).to be false
      end

      it 'returns empty captures' do
        regex.valid?
        expect(regex.captures).to eq([])
      end

      it 'returns no match positions' do
        regex.valid?
        expect(regex.match_positions).to eq([])
      end
    end

    context 'with invalid regex syntax' do
      let(:regex) { described_class.new(
        expression: '[a-z',
        test_string: 'abc'
      ) }

      it 'is invalid' do
        expect(regex).not_to be_valid
      end

      it 'adds error for invalid syntax' do
        regex.valid?
        expect(regex.errors[:base].first).to match(
          /premature end of char-class/
        )
      end

      it 'returns no match positions' do
        regex.valid?
        expect(regex.match_positions).to eq([])
      end
    end
  end

  describe '#named_captures' do
    context 'with single named capture' do
      let(:regex) { described_class.new(
        expression: '(?<word>hello)',
        test_string: 'hello'
      ) }

      it 'returns single named capture' do
        regex.valid?
        expect(regex.named_captures).to eq(
          [{ 'word' => 'hello' }]
        )
      end
    end

    context 'with no named capture' do
      let(:regex) { described_class.new(
        expression: '(hello)',
        test_string: 'hello'
      ) }

      it 'returns empty array since no named captures' do
        regex.valid?
        expect(regex.named_captures).to eq([])
      end
    end
  end

  describe '#diagram_svg' do
    let(:regex) { described_class.new(
      expression: 'a+',
      test_string: 'aaa'
    ) }

    before do
      allow(RegexpDiagram).to receive(
        :create_svg_from_regex
      ).and_return('<svg><text>Diagram</text></svg>')
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
      expect(described_class.new(
        expression: '',
        test_string: 'test'
      )).to be_unready
    end

    it 'returns true if test_string is blank' do
      expect(described_class.new(
        expression: 'abc',
        test_string: ''
      )).to be_unready
    end

    it 'returns false if both are present' do
      expect(described_class.new(
        expression: 'abc',
        test_string: 'abc'
      )).not_to be_unready
    end
  end

  describe 'regex options' do
    context 'with i (ignore case) option' do
      let(:regex) { described_class.new(
        expression: '^hello',
        test_string: 'HeLLo',
        options: 'i'
      ) }

      it 'is valid' do
        expect(regex).to be_valid
      end

      it 'matches successfully' do
        regex.valid?
        expect(regex.match_positions).to eq(
          [{ start: 0, end: 5, index: 0, invisible: true }]
        )
      end

      it 'returns empty captures' do
        regex.valid?
        expect(regex.captures).to eq([])
      end
    end

    context 'with m (multiline) option' do
      let(:regex) { described_class.new(
        expression: 'hello.hello',
        test_string: "hello\nhello",
        options: 'm'
      ) }

      it 'is valid' do
        expect(regex).to be_valid
      end

      it 'matches across lines with dot' do
        regex.valid?
        expect(regex.match_positions).to eq(
          [{ start: 0, end: 11, index: 0, invisible: true }]
        )
      end

      it 'returns empty captures' do
        regex.valid?
        expect(regex.captures).to eq([])
      end
    end

    context 'with x (verbose) option' do
      let(:regex) { described_class.new(
        expression: /
        ^          # line start
        hello      # match "hello"
        $          # line end
        /x,
        test_string: 'hello'
      ) }

      it 'is valid' do
        expect(regex).to be_valid
      end

      it 'matches successfully with verbose option' do
        regex.valid?
        expect(regex.match_positions).to eq(
          [{ start: 0, end: 5, index: 0, invisible: true }]
        )
      end

      it 'returns empty captures' do
        regex.valid?
        expect(regex.captures).to eq([])
      end
    end

    context 'with mx (multiline and verbose) options' do
      let(:regex) { described_class.new(
        expression: /
        ^hello     # line start
        /mx,
        test_string: "hello\nhello"
      ) }

      it 'is valid' do
        expect(regex).to be_valid
      end

      it 'matches at the start of each line' do
        regex.valid?
        expect(regex.match_positions).to eq(
          [{ start: 0, end: 5, index: 0, invisible: true },
           { start: 6, end: 11, index: 1, invisible: true }]
        )
      end

      it 'returns empty captures for multiline match' do
        regex.valid?
        expect(regex.captures).to eq([])
      end
    end

    context 'when option is not set' do
      let(:regex) { described_class.new(
        expression: '^hello',
        test_string: "hello"
      ) }

      it 'is valid' do
        expect(regex).to be_valid
      end

      it 'matches successfully' do
        regex.valid?
        expect(regex.match_positions).to eq(
          [{ start: 0, end: 5, index: 0, invisible: true }]
        )
      end

      it 'returns empty captures' do
        regex.valid?
        expect(regex.captures).to eq([])
      end
    end

    context 'when unsupported options are provided' do
      let(:regex) { described_class.new(
        expression: '^hello',
        test_string: "hello",
        options: 'o'
      ) }

      it 'is valid' do
        expect(regex).to be_valid
      end
    end
  end

  describe '#perform_substitution' do
    context 'with simple substitution' do
      let(:regex) {
        described_class.new(
          expression: 'h(e)llo',
          test_string: 'hello hello',
          substitution: 'H\\1LLO'
        )
      }

      it 'returns substituted string with markup' do
        regex.valid?
        regex.perform_substitution
        expect(regex.substitution_result).to eq(
          '<mark class="bg-green-300 p-0.5 rounded-xs text-green-900">HeLLO</mark> <mark class="bg-green-300 p-0.5 rounded-xs text-green-900">HeLLO</mark>'
        )
      end
    end

    context 'with named capture substitution' do
      let(:regex) {
        described_class.new(
          expression: '(?<word>hello)',
          test_string: 'hello hello',
          substitution: '[\k<word>]'
        )
      }

      it 'returns substituted string with named captures and markup' do
        regex.valid?
        regex.perform_substitution
        expect(regex.substitution_result).to eq(
          'hello hello'.gsub(/(?<word>hello)/, '<mark class="bg-green-300 p-0.5 rounded-xs text-green-900">[hello]</mark>')
        )
      end
    end

    context 'with no substitution string' do
      let(:regex) {
        described_class.new(
          expression: 'hello',
          test_string: 'hello world',
          substitution: nil
        )
      }

      it 'returns nil for substitution' do
        regex.valid?
        regex.perform_substitution
        expect(regex.substitution_result).to be_nil
      end
    end

    context 'with invalid regex' do
      let(:regex) {
        described_class.new(
          expression: '[a-z',
          test_string: 'abc',
          substitution: 'X'
        )
      }

      it 'returns nil when regex is invalid' do
        regex.valid?
        regex.perform_substitution
        expect(regex.substitution_result).to be_nil
      end
    end

    context 'with no matches' do
      let(:regex) {
        described_class.new(
          expression: '(goodbye)',
          test_string: 'hello hello',
          substitution: 'BYE'
        )
      }

      it 'returns original string with no substitutions applied' do
        regex.valid?
        regex.perform_substitution
        expect(regex.substitution_result).to eq('hello hello')
      end
    end
  end

  describe 'edge cases and advanced patterns' do
    context 'when expression and test string are empty' do
      let(:regex) {
        described_class.new(expression: '', test_string: '')
      }

      it 'is invalid due to blank expression' do
        expect(regex).not_to be_valid
      end
    end

    context 'when options are reordered' do
      let(:regex_case_sensitive_first) { described_class.new(expression: '^hello', test_string: 'HeLLo', options: 'im') }
      let(:regex_case_sensitive_second) { described_class.new(expression: '^hello', test_string: 'HeLLo', options: 'mi') }

      it 'behaves identically regardless of option order' do
        expect(regex_case_sensitive_first).to be_valid
        expect(regex_case_sensitive_second).to be_valid
        regex_case_sensitive_first.valid?
        regex_case_sensitive_second.valid?
        expect(regex_case_sensitive_first.match_positions).to eq(regex_case_sensitive_second.match_positions)
      end
    end

    context 'when using surrogate pairs (emoji)' do
      let(:regex) {
        described_class.new(expression: '😀', test_string: 'test😀test')
      }

      it 'matches emoji characters correctly' do
        regex.valid?
        expect(regex.match_positions).to eq([
          { start: 4, end: 5, index: 0, invisible: true }
        ])
      end
    end

    context 'when case sensitivity is not ignored' do
      let(:regex) {
        described_class.new(expression: 'hello', test_string: 'HELLO')
      }

      it 'does not match if case is different and no i option is set' do
        regex.valid?
        expect(regex.match_success).to be false
      end
    end

    context 'when invalid substitution backreference is used' do
      let(:regex) {
        described_class.new(
          expression: '(hello)',
          test_string: 'hello',
          substitution: '\\9'
        )
      }

      it 'does not raise error and returns original string fallback for substitution' do
        regex.valid?
        regex.perform_substitution
        expect(regex.substitution_result).to eq('hello')
      end
    end

    context 'when using lookahead and non-capturing groups' do
      let(:regex) {
        described_class.new(expression: '(?=foo)(?:foo)', test_string: 'foobar')
      }

      it 'matches foo using lookahead and non-capturing' do
        regex.valid?
        expect(regex.match_positions).to eq([
          { start: 0, end: 3, index: 0, invisible: true }
        ])
        expect(regex.captures).to eq([]) # no capturing
      end
    end
  end
end
