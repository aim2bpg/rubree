require 'rails_helper'

RSpec.describe RegularExpression::RubyCodeGenerator do
  describe '#generate' do
    context 'when expression and test_string are present' do
      let(:generator) {
        described_class.new(
          regular_expression: Regexp.new('h(e)llo'),
          test_string: 'hello'
        )
      }

      it 'generates ruby code with captures' do
        code = generator.generate
        expect(code).to include('pattern = /h(e)llo/')
        expect(code).to include('test_string = "hello"')
        expect(code).to include('if match = pattern.match(test_string)')
        expect(code).to include('puts "#{i + 1}: #{cap}"')
      end

      it 'matches the expected generated Ruby code' do
        expected_code = <<~RUBY
          # Ruby code for testing the regex
          pattern = /h(e)llo/
          test_string = "hello"

          # Match and captures
          if match = pattern.match(test_string)
            # Numbered captures:
            match.captures.each_with_index do |cap, i|
              puts "\#{i + 1}: \#{cap}"
            end
          else
            puts "No match."
          end
        RUBY
        code = generator.generate
        expect(code).to eq(expected_code.chomp)
      end
    end

    context 'when substitution is present' do
      let(:generator) {
        described_class.new(
          regular_expression: Regexp.new('h(e)llo'),
          test_string: 'hello',
          substitution: 'X\\1Y'
        )
      }

      it 'generates ruby code with substitution' do
        code = generator.generate
        expect(code).to include('result = test_string.gsub(pattern, "X\\\\1Y")')
        expect(code).to include('puts result')
      end

      it 'matches the expected generated Ruby code with substitution' do
        expected_code = <<~RUBY
          # Ruby code for testing the regex
          pattern = /h(e)llo/
          test_string = "hello"

          # With substitution
          result = test_string.gsub(pattern, "X\\\\1Y")
          puts result
        RUBY
        code = generator.generate
        expect(code).to eq(expected_code)
      end
    end

    context 'when expression is blank' do
      it 'returns nil' do
        generator = described_class.new(
          regular_expression: nil,
          test_string: 'foo'
        )
        expect(generator.generate).to be_nil
      end
    end

    context 'when test_string is blank' do
      it 'returns nil' do
        generator = described_class.new(
          regular_expression: Regexp.new('foo'),
          test_string: nil
        )
        expect(generator.generate).to be_nil
      end
    end

    context 'when no match is found in the test string' do
      let(:generator) {
        described_class.new(
          regular_expression: Regexp.new('goodbye'),
          test_string: 'hello'
        )
      }

      it 'generates ruby code to print "No match."' do
        code = generator.generate
        expect(code).to include('puts "No match."')
      end

      it 'matches the expected generated Ruby code for no match' do
        expected_code = <<~RUBY
          # Ruby code for testing the regex
          pattern = /goodbye/
          test_string = "hello"

          # Match and captures
          if match = pattern.match(test_string)
            # Numbered captures:
            match.captures.each_with_index do |cap, i|
              puts "\#{i + 1}: \#{cap}"
            end
          else
            puts "No match."
          end
        RUBY
        code = generator.generate
        expect(code).to eq(expected_code.chomp)
      end
    end

    context 'when named captures are present in the regexp' do
      let(:generator) {
        described_class.new(
          regular_expression: Regexp.new('(?<greeting>hello) (?<farewell>goodbye)'),
          test_string: 'hello goodbye'
        )
      }

      it 'generates ruby code with named captures' do
        code = generator.generate
        expect(code).to include('puts "greeting: #{match[:greeting]}"')
        expect(code).to include('puts "farewell: #{match[:farewell]}"')
      end

      it 'matches the expected generated Ruby code with named captures' do
        expected_code = <<~RUBY
          # Ruby code for testing the regex
          pattern = /(?<greeting>hello) (?<farewell>goodbye)/
          test_string = "hello goodbye"

          # Match and captures
          if match = pattern.match(test_string)
            # Named captures:
            puts "greeting: \#{match[:greeting]}"
            puts "farewell: \#{match[:farewell]}"
          else
            puts "No match."
          end
        RUBY
        code = generator.generate
        expect(code).to eq(expected_code.chomp)
      end
    end
  end
end
