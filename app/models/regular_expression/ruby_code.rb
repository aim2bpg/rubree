class RegularExpression
  class RubyCode
    include ActiveModel::Model

    attr_accessor :regular_expression, :test_string, :substitution_string

    def initialize(regular_expression:, test_string:, substitution_string: nil)
      @regular_expression = regular_expression
      @test_string = test_string
      @substitution_string = substitution_string
    end

    def generate
      return nil if regular_expression.nil? || test_string.nil?

      code_parts = []

      # Always include match and captures section
      if regular_expression.names.any?
        named_captures = regular_expression.names.map do |name|
          "  puts \"    #{name}: \#{match[:#{name}]}\""
        end.join("\n")

        code_parts << <<~RUBY.chomp
          # Ruby code for testing the regex
          pattern = #{regular_expression.inspect}
          test_string = #{test_string.inspect}

          puts "Pattern: \#{pattern.inspect}"
          puts "Test string: \#{test_string}"
          puts

          # Match and captures
          if match = pattern.match(test_string)
            puts "Match result:"
            puts "  Full match: \#{match[0]}"
            if match.names.any?
              puts "  Named captures:"
          #{named_captures}
            end
          else
            puts "No match."
          end
        RUBY
      else
        code_parts << <<~RUBY.chomp
          # Ruby code for testing the regex
          pattern = #{regular_expression.inspect}
          test_string = #{test_string.inspect}

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
      end

      # Add substitution section if substitution_string is present
      if substitution_string&.present?
        code_parts << <<~RUBY.chomp
          # With substitution
          result = test_string.gsub(pattern, #{substitution_string.inspect})
          puts "Substitution result: \#{result}"
        RUBY
      end

      code_parts.join("\n\n")
    rescue => e
      "# Error generating Ruby code: #{e.message}"
    end
  end
end
