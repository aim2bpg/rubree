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
      if substitution_string.match?(/\\\d+/)
        test_string.match(@regexp)
        valid_groups = Regexp.last_match&.captures&.size.to_i
        max_ref = substitution_string.scan(/\\(\d+)/).flatten.map(&:to_i).max.to_i
        if max_ref > valid_groups
          @substitution_result = test_string
          return
        end
      end

      changed = false

      @substitution_result = test_string.gsub(@regexp) do |matched_text|
        match_data = Regexp.last_match

        replaced_text = substitution_string.gsub(/\\(\d+|k<[^>]+>)/) do |ref|
          key = ref[1..]

          if key.start_with?("k<")
            name = key[2..-2]
            match_data.named_captures[name] || ""
          else
            index = key.to_i
            match_data[index] || ""
          end
        rescue
          matched_text
        end

        changed = true if replaced_text != matched_text
        content = replaced_text.empty? ? "" : ERB::Util.h(replaced_text)
        %Q(<mark class="bg-green-300 p-0.5 rounded-xs text-green-900">#{content}</mark>)
      end

      @substitution_result = test_string unless changed
      @substitution_result = @substitution_result.html_safe if @substitution_result.respond_to?(:html_safe)
    end

    def validate_capture_references
      return if @regexp.nil? || substitution_string.blank?

      numbered_refs = substitution_string.scan(/\\(\d+)/).flatten.map(&:to_i)
      named_refs = substitution_string.scan(/\\k<([^>]+)>/).flatten

      match = test_string.match(@regexp)
      valid_groups = match&.captures&.size.to_i
      valid_names = match&.names || []

      if numbered_refs.any?
        max_ref = numbered_refs.max
        if max_ref > valid_groups
          errors.add(:substitution_string, "References non-existent numbered capture group(s): (\\#{max_ref})")
        end
      end

      invalid_names = named_refs.reject { |name| valid_names.include?(name) }
      if invalid_names.any?
        errors.add(:substitution_string, "References non-existent named capture group(s): #{invalid_names.join(', ')}")
      end
    end
  end
end
