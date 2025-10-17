require 'rails_helper'

RSpec.describe RegexpSubstitutor do
  describe '.perform_substitution' do
    context 'when regex contains simple substitution with numbered captures' do
      let(:expression) { 'h(e)llo' }
      let(:test_string) { 'hello hello' }
      let(:substitution) { 'H\\1LLO' }

      it 'substitutes and highlights matches' do
        result = described_class.perform_substitution(expression, test_string, substitution, '')
        expect(result).to include('<mark')
        expect(result).to include('HeLLO')
      end
    end

    context 'when regex contains substitution with named capture group' do
      let(:expression) { '(?<word>hello)' }
      let(:test_string) { 'hello hello' }
      let(:substitution) { '[\k<word>]' }

      it 'correctly substitutes named capture and highlights' do
        result = described_class.perform_substitution(expression, test_string, substitution, '')
        expect(result).to include('<mark')
        expect(result).to include('[hello]')
      end
    end

    context 'when regex contains no substitution string provided' do
      it 'returns nil' do
        result = described_class.perform_substitution('hello', 'hello world', nil, '')
        expect(result).to be_nil
      end
    end

    context 'when regex contains invalid regex expression' do
      it 'returns nil and does not raise' do
        expect {
          result = described_class.perform_substitution('[a-z', 'abc', 'X', '')
          expect(result).to be_nil
        }.not_to raise_error
      end
    end

    context 'when regex contains no matches found' do
      it 'returns original test string unchanged' do
        result = described_class.perform_substitution('(goodbye)', 'hello hello', 'BYE', '')
        expect(result).to eq('hello hello')
      end
    end

    context 'when regex contains empty substitution string' do
      it 'returns empty string wrapped with highlight markup' do
        result = described_class.perform_substitution('(hello)', 'hello', '', '')
        expect(result).to include('<mark')
      end
    end

    context 'when regex contains invalid backreference in substitution' do
      it 'returns original string without raising' do
        result = described_class.perform_substitution('(hello)', 'hello', '\\9', '')
        expect(result).to eq('hello')
      end
    end
  end
end
