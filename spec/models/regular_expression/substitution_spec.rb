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
