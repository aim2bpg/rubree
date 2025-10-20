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

      if substitution_string&.present?
        <<~RUBY
          # Ruby code for testing the regex
          pattern = #{regular_expression.inspect}
          test_string = #{test_string.inspect}

          # With substitution
          result = test_string.gsub(pattern, #{substitution_string.inspect})
          puts result
        RUBY
      else
        if regular_expression.names.any?
          named_captures = regular_expression.names.map do |name|
            "puts \"#{name}: \#{match[:#{name}]}\""
          end.join("\n  ")

          <<~RUBY
            # Ruby code for testing the regex
            pattern = #{regular_expression.inspect}
            test_string = #{test_string.inspect}

            # Match and captures
            if match = pattern.match(test_string)
              # Named captures:
              #{named_captures}
            else
              puts "No match."
            end
          RUBY
        else
          <<~RUBY
            # Ruby code for testing the regex
            pattern = #{regular_expression.inspect}
            test_string = #{test_string.inspect}

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
        end.chomp
      end
    rescue => e
      "# Error generating Ruby code: #{e.message}"
    end
  end
end
