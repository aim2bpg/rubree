class RegexpCodeGenerator
  attr_reader :regexp, :test_string, :substitution

  def initialize(regexp:, test_string:, substitution: nil)
    @regexp = regexp
    @test_string = test_string
    @substitution = substitution
  end

  def generate
    return nil if regexp.nil? || test_string.nil?

    if substitution&.present?
      <<~RUBY
        # Ruby code for testing the regex
        pattern = #{regexp.inspect}
        test_string = #{test_string.inspect}

        # With substitution
        result = test_string.gsub(pattern, #{substitution.inspect})
        puts result
      RUBY
    else
      if regexp.names.any?
        named_captures = regexp.names.map do |name|
          "puts \"#{name}: \#{match[:#{name}]}\""
        end.join("\n  ")

        <<~RUBY
          # Ruby code for testing the regex
          pattern = #{regexp.inspect}
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
          pattern = #{regexp.inspect}
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
