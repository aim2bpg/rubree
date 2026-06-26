class RegularExpression
  class Substitution
    include ActiveModel::Model

    attr_accessor :regular_expression, :test_string, :substitution_string
    attr_reader :substitution_result

    validates :regular_expression, presence: true
    validates :test_string, presence: true
    validates :substitution_string, presence: true
    validate :validate_capture_references

    def initialize(regular_expression:, test_string:, substitution_string:)
      @regular_expression = regular_expression
      @test_string = test_string
      @substitution_string = substitution_string
      @substitution_result = nil

      begin
        @regexp = Regexp.new(regular_expression)
      rescue RegexpError => e
        @regexp = nil
        errors.add(:regular_expression, "is invalid: #{e.message}")
      end

      run_substitution if @regexp && !substitution_string.nil?
    end

    def result
      substitution_result
    end

    private

    def run_substitution
      refs = parse_refs(substitution_string)

      if refs[:numbered].any?
        test_string.match(@regexp)
        valid_groups = Regexp.last_match&.captures&.size.to_i
        if refs[:numbered].max > valid_groups
          @substitution_result = ERB::Util.h(test_string)
          return
        end
      end

      result = "".html_safe
      last_pos = 0
      changed = false

      test_string.scan(@regexp) do
        match_data = Regexp.last_match
        match_start = match_data.begin(0)
        match_end   = match_data.end(0)

        result << ERB::Util.h(test_string[last_pos...match_start])

        replaced_text = expand_substitution(substitution_string, match_data)

        changed = true if replaced_text != match_data[0]
        content = replaced_text.empty? ? "" : ERB::Util.h(replaced_text)
        result << %(<mark class="bg-green-300 p-0.5 rounded-xs text-green-900">#{content}</mark>).html_safe

        last_pos = match_end
      end

      result << ERB::Util.h(test_string[last_pos..])

      @substitution_result = changed ? result : ERB::Util.h(test_string)
    end

    # Processes the substitution template left-to-right, matching Ruby's gsub
    # string-replacement semantics:
    #   \\       → literal backslash
    #   \0..\9   → numbered capture group (match_data[n])
    #   \k<name> → named capture group
    #   \x       → unknown escape, preserved as \x
    def expand_substitution(template, match_data)
      result = +""
      i = 0
      while i < template.length
        if template[i] == "\\"
          break if i + 1 >= template.length

          nxt = template[i + 1]
          case nxt
          when "\\"
            result << "\\"
            i += 2
          when /[0-9]/
            result << (match_data[nxt.to_i] || "")
            i += 2
          else
            tail = template[(i + 1)..]
            if tail =~ /\Ak<([^>]+)>/
              result << (match_data.named_captures[Regexp.last_match(1)] || "")
              i += 1 + Regexp.last_match(0).length
            else
              result << "\\" << nxt
              i += 2
            end
          end
        else
          result << template[i]
          i += 1
        end
      end
      result
    end

    # Parses capture group references from the template using the same
    # left-to-right logic as expand_substitution, so that \\ does not
    # cause the following digit to be misidentified as a reference.
    def parse_refs(template)
      numbered = []
      named    = []
      i = 0
      while i < template.length
        if template[i] == "\\"
          break if i + 1 >= template.length

          nxt = template[i + 1]
          case nxt
          when "\\"
            i += 2
          when /[0-9]/
            numbered << nxt.to_i
            i += 2
          else
            tail = template[(i + 1)..]
            if tail =~ /\Ak<([^>]+)>/
              named << Regexp.last_match(1)
              i += 1 + Regexp.last_match(0).length
            else
              i += 2
            end
          end
        else
          i += 1
        end
      end
      { numbered:, named: }
    end

    def validate_capture_references
      return if @regexp.nil? || substitution_string.blank?

      refs = parse_refs(substitution_string)
      match = test_string.match(@regexp)
      valid_groups = match&.captures&.size.to_i
      valid_names = match&.names || []

      if refs[:numbered].any?
        max_ref = refs[:numbered].max
        if max_ref > valid_groups
          errors.add(:substitution_string, "References non-existent numbered capture group(s): (\\#{max_ref})")
        end
      end

      invalid_names = refs[:named].reject { |name| valid_names.include?(name) }
      if invalid_names.any?
        errors.add(:substitution_string, "References non-existent named capture group(s): #{invalid_names.join(', ')}")
      end
    end
  end
end
