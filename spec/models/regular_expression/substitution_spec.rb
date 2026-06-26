require 'rails_helper'

RSpec.describe RegularExpression::Substitution do
  describe 'basic cases' do
    it 'escapes HTML in substitution result' do
      sub = described_class.new(
        regular_expression: '(foo)',
        test_string: 'foo foo foo',
        substitution_string: '<script>alert(1)</script>'
      )

      # substitution wraps each replaced fragment in a marked element and escapes HTML
      expect(sub.result).to include('&lt;script&gt;alert(1)&lt;/script&gt;')
      expect(sub.errors).to be_empty
    end

    it 'returns original string when invalid backreference used' do
      sub = described_class.new(
        regular_expression: '(foo)',
        test_string: 'foo',
        substitution_string: '\\2!'
      )

      expect(sub.result).to eq('foo')
    end

    it 'supports named captures in substitution and escapes content' do
      sub = described_class.new(
        regular_expression: '(?<word>foo)',
        test_string: 'foo',
        substitution_string: '\\k<word><script>'
      )

      expect(sub.result).to include('foo')
      expect(sub.result).to include('&lt;script&gt;')
    end
  end

  describe '#result' do
    subject(:substitution_result) do
      described_class.new(
        regular_expression: regular_expression,
        test_string: test_string,
        substitution_string: substitution_string
      ).result
    end

    context 'with simple numbered capture' do
      let(:regular_expression) { 'h(e)llo' }
      let(:test_string) { 'hello hello' }
      let(:substitution_string) { 'H\\1LLO' }

      it 'returns substituted and highlighted result' do
        expect(substitution_result).to include('<mark')
        expect(substitution_result).to include('HeLLO')
      end
    end

    context 'with named capture group' do
      let(:regular_expression) { '(?<word>hello)' }
      let(:test_string) { 'hello hello' }
      let(:substitution_string) { '[\k<word>]' }

      it 'uses named capture correctly in substitution' do
        expect(substitution_result).to include('<mark')
        expect(substitution_result).to include('[hello]')
      end
    end

    context 'when substitution is nil' do
      let(:regular_expression) { 'hello' }
      let(:test_string) { 'hello world' }
      let(:substitution_string) { nil }

      it 'returns nil' do
        expect(substitution_result).to be_nil
      end
    end

    context 'with invalid regular expression' do
      let(:regular_expression) { '[a-z' } # unclosed character class
      let(:test_string) { 'abc' }
      let(:substitution_string) { 'X' }

      it 'returns nil without raising error' do
        expect { substitution_result }.not_to raise_error
        expect(substitution_result).to be_nil
      end
    end

    context 'when no matches are found' do
      let(:regular_expression) { '(goodbye)' }
      let(:test_string) { 'hello hello' }
      let(:substitution_string) { 'BYE' }

      it 'returns original test string unchanged' do
        expect(substitution_result).to eq('hello hello')
      end
    end

    context 'when substitution string is empty' do
      let(:regular_expression) { '(hello)' }
      let(:test_string) { 'hello' }
      let(:substitution_string) { '' }

      it 'wraps empty result in highlight markup' do
        expect(substitution_result).to include('<mark')
        expect(substitution_result).to include('></mark>') # empty inner content
      end
    end

    context 'when substitution references a non-existent group' do
      let(:regular_expression) { '(hello)' }
      let(:test_string) { 'hello' }
      let(:substitution_string) { '\\9' }

      it 'returns original string' do
        expect(substitution_result).to eq('hello')
      end
    end
  end

  describe 'backslash semantics (Ruby gsub compatibility)' do
    def result_for(pattern:, test_string:, substitution:)
      described_class.new(
        regular_expression: pattern,
        test_string: test_string,
        substitution_string: substitution
      ).result
    end

    it 'converts \\\\ (two backslashes) to a single literal backslash' do
      # Ruby gsub: gsub(pattern, "\\\\") → "\" (1 backslash)
      result = result_for(pattern: 'X', test_string: 'X', substitution: "\\\\")
      expect(result).to include("\\")
      expect(result).not_to include("\\\\")
    end

    it 'treats \\\\1 as literal backslash + digit 1, not as capture group 1' do
      # \\ consumes the first two chars as a literal \; the remaining 1 is literal
      result = result_for(pattern: '(foo)', test_string: 'foo', substitution: "\\\\1")
      expect(result).to include("\\1")
      expect(result).not_to include("foo")
    end

    it 'still expands \\1 as capture group 1' do
      result = result_for(pattern: '(hello)', test_string: 'hello world', substitution: "\\1!")
      expect(result).to include("hello!")
    end

    it 'preserves unknown escape sequences unchanged' do
      # \n (backslash + n, not a digit) is an unknown escape → kept as \n
      result = result_for(pattern: 'X', test_string: 'X', substitution: "\\n")
      expect(result).to include("\\n")
    end
  end

  describe 'HTML escaping / XSS prevention' do
    def result_for(pattern:, test_string:, substitution:)
      described_class.new(
        regular_expression: pattern,
        test_string: test_string,
        substitution_string: substitution
      ).result
    end

    it 'escapes HTML tags in non-matched prefix before a match' do
      result = result_for(pattern: 'MARKER', test_string: '<script>evil()</script>MARKER', substitution: 'safe')
      expect(result).to include('&lt;script&gt;evil()&lt;/script&gt;')
      expect(result).not_to include('<script>')
    end

    it 'escapes HTML tags in non-matched suffix after a match' do
      result = result_for(pattern: 'MARKER', test_string: 'MARKERsuffix<b>bold</b>', substitution: 'safe')
      expect(result).to include('&lt;b&gt;bold&lt;/b&gt;')
      expect(result).not_to include('<b>bold</b>')
    end

    it 'escapes HTML tags in non-matched text between matches' do
      result = result_for(pattern: ',', test_string: 'a,<b>b</b>,c', substitution: 'X')
      expect(result).to include('&lt;b&gt;b&lt;/b&gt;')
      expect(result).not_to include('<b>')
    end

    it 'escapes & and > in non-matched portions' do
      result = result_for(pattern: ',', test_string: 'a & b,c > d', substitution: 'X')
      expect(result).to include('a &amp; b')
      expect(result).to include('c &gt; d')
    end

    it 'escapes HTML in test string when no match is found' do
      result = result_for(pattern: 'xyz', test_string: '<b>no match</b>', substitution: 'X')
      expect(result).to include('&lt;b&gt;no match&lt;/b&gt;')
      expect(result).not_to include('<b>')
    end

    it 'escapes HTML in test string on early return due to invalid backreference' do
      result = result_for(pattern: '(foo)', test_string: '<b>foo</b>', substitution: '\\2!')
      expect(result).to include('&lt;b&gt;foo&lt;/b&gt;')
      expect(result).not_to include('<b>')
    end

    it 'marks result as html_safe' do
      result = result_for(pattern: 'foo', test_string: 'foo bar', substitution: 'baz')
      expect(result).to be_html_safe
    end
  end

  describe 'validation of capture references' do
    subject(:substitutor) do
      described_class.new(
        regular_expression: regular_expression,
        test_string: test_string,
        substitution_string: substitution_string
      )
    end

    before { substitutor.valid? }

    context 'with valid numbered reference' do
      let(:regular_expression) { '(hello)' }
      let(:test_string) { 'hello' }
      let(:substitution_string) { '\\1' }

      it 'does not add an error' do
        expect(substitutor.errors[:substitution_string]).to be_empty
      end
    end

    context 'with invalid numbered reference' do
      let(:regular_expression) { '(hello)' }
      let(:test_string) { 'hello' }
      let(:substitution_string) { '\\9' }

      it 'adds a validation error' do
        expect(substitutor.errors[:substitution_string]).to include("References non-existent numbered capture group(s): (\\9)")
      end
    end

    context 'with valid named reference' do
      let(:regular_expression) { '(?<word>hello)' }
      let(:test_string) { 'hello' }
      let(:substitution_string) { '\k<word>' }

      it 'does not add an error' do
        expect(substitutor.errors[:substitution_string]).to be_empty
      end
    end

    context 'with invalid named reference' do
      let(:regular_expression) { '(?<word>hello)' }
      let(:test_string) { 'hello' }
      let(:substitution_string) { '\k<missing>' }

      it 'adds a validation error' do
        expect(substitutor.errors[:substitution_string]).to include("References non-existent named capture group(s): missing")
      end
    end
  end
end
