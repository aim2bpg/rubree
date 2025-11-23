require 'rails_helper'

RSpec.describe RegularExpression::RubyCode do
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
        expect(code).to include('puts "Pattern: #{pattern.inspect}"')
        expect(code).to include('puts "Test string: #{test_string}"')
        expect(code).to include('if match = pattern.match(test_string)')
        expect(code).to include('puts "Match result:"')
      end

      it 'matches the expected generated Ruby code' do
        expected_code = <<~RUBY
          # Ruby code for testing the regex
          pattern = /h(e)llo/
          test_string = "hello"

          puts "Pattern: \#{pattern.inspect}"
          puts "Test string: \#{test_string}"
          puts

          # Match and captures
          if match = pattern.match(test_string)
            puts "Match result:"
            puts "  Full match: \#{match[0]}"
            if match.captures.any?
              puts "  Numbered captures:"
              match.captures.each_with_index do |cap, i|
                puts "    \#{i + 1}: \#{cap}"
              end
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
          substitution_string: 'X\\1Y'
        )
      }

      it 'generates ruby code with both match/captures and substitution' do
        code = generator.generate
        expect(code).to include('# Match and captures')
        expect(code).to include('if match = pattern.match(test_string)')
        expect(code).to include('# With substitution')
        expect(code).to include('result = test_string.gsub(pattern, "X\\\\1Y")')
        expect(code).to include('puts "Substitution result: #{result}"')
      end

      it 'matches the expected generated Ruby code with substitution' do
        expected_code = <<~RUBY.chomp
          # Ruby code for testing the regex
          pattern = /h(e)llo/
          test_string = "hello"

          puts "Pattern: \#{pattern.inspect}"
          puts "Test string: \#{test_string}"
          puts

          # Match and captures
          if match = pattern.match(test_string)
            puts "Match result:"
            puts "  Full match: \#{match[0]}"
            if match.captures.any?
              puts "  Numbered captures:"
              match.captures.each_with_index do |cap, i|
                puts "    \#{i + 1}: \#{cap}"
              end
            end
          else
            puts "No match."
          end

          # With substitution
          result = test_string.gsub(pattern, "X\\\\1Y")
          puts "Substitution result: \#{result}"
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

          puts "Pattern: \#{pattern.inspect}"
          puts "Test string: \#{test_string}"
          puts

          # Match and captures
          if match = pattern.match(test_string)
            puts "Match result:"
            puts "  Full match: \#{match[0]}"
            if match.captures.any?
              puts "  Numbered captures:"
              match.captures.each_with_index do |cap, i|
                puts "    \#{i + 1}: \#{cap}"
              end
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
        expect(code).to include('puts "    greeting: #{match[:greeting]}"')
        expect(code).to include('puts "    farewell: #{match[:farewell]}"')
      end

      it 'matches the expected generated Ruby code with named captures' do
        expected_code = <<~RUBY
          # Ruby code for testing the regex
          pattern = /(?<greeting>hello) (?<farewell>goodbye)/
          test_string = "hello goodbye"

          puts "Pattern: \#{pattern.inspect}"
          puts "Test string: \#{test_string}"
          puts

          # Match and captures
          if match = pattern.match(test_string)
            puts "Match result:"
            puts "  Full match: \#{match[0]}"
            if match.names.any?
              puts "  Named captures:"
            puts "    greeting: \#{match[:greeting]}"
            puts "    farewell: \#{match[:farewell]}"
            end
          else
            puts "No match."
          end
        RUBY
        code = generator.generate
        expect(code).to eq(expected_code.chomp)
      end
    end

    context 'when named captures and substitution are both present' do
      let(:generator) {
        described_class.new(
          regular_expression: Regexp.new('(?<month>\\d{1,2})/(?<day>\\d{1,2})/(?<year>\\d{4})'),
          test_string: "Today's date is: 11/23/2025.",
          substitution_string: '\\k<year>/\\k<month>/\\k<day>'
        )
      }

      it 'generates ruby code with both named captures and substitution' do
        code = generator.generate
        expect(code).to include('# Match and captures')
        expect(code).to include('puts "    month: #{match[:month]}"')
        expect(code).to include('puts "    day: #{match[:day]}"')
        expect(code).to include('puts "    year: #{match[:year]}"')
        expect(code).to include('# With substitution')
        expect(code).to include('result = test_string.gsub(pattern, "\\\\k<year>/\\\\k<month>/\\\\k<day>")')
      end

      it 'matches the expected generated Ruby code with named captures and substitution' do
        expected_code = <<~RUBY.chomp
          # Ruby code for testing the regex
          pattern = /(?<month>\\d{1,2})\\/(?<day>\\d{1,2})\\/(?<year>\\d{4})/
          test_string = "Today's date is: 11/23/2025."

          puts "Pattern: \#{pattern.inspect}"
          puts "Test string: \#{test_string}"
          puts

          # Match and captures
          if match = pattern.match(test_string)
            puts "Match result:"
            puts "  Full match: \#{match[0]}"
            if match.names.any?
              puts "  Named captures:"
            puts "    month: \#{match[:month]}"
            puts "    day: \#{match[:day]}"
            puts "    year: \#{match[:year]}"
            end
          else
            puts "No match."
          end

          # With substitution
          result = test_string.gsub(pattern, "\\\\k<year>/\\\\k<month>/\\\\k<day>")
          puts "Substitution result: \#{result}"
        RUBY
        code = generator.generate
        expect(code).to eq(expected_code)
      end
    end
  end
end
