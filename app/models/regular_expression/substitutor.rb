class RegularExpression
  class Substitutor
    include ActiveModel::Model

    attr_accessor :regular_expression, :test_string, :substitution
    attr_reader :substitution_result

    validates :regular_expression, presence: true
    validates :test_string, presence: true
    validates :substitution, presence: true
    validate :validate_capture_references

    def initialize(attributes = {})
      super
      @substitution_result = nil

      begin
        @regexp = Regexp.new(regular_expression)
      rescue RegexpError => e
        @regexp = nil
        errors.add(:regular_expression, "is invalid: #{e.message}")
      end
    end

    def self.perform(regular_expression, test_string, substitution)
      new(
        regular_expression: regular_expression,
        test_string: test_string,
        substitution: substitution
      ).perform
    end

    def perform
      return nil if errors.any? || @regexp.nil? || substitution.nil?

      if substitution.match?(/\\\d+/)
        test_string.match(@regexp)
        valid_groups = Regexp.last_match&.captures&.size.to_i

        max_ref = substitution.scan(/\\(\d+)/).flatten.map(&:to_i).max.to_i
        if max_ref > valid_groups
          return test_string
        end
      end

      changed = false

      @substitution_result = test_string.gsub(@regexp) do |matched_text|
        match_data = Regexp.last_match

        replaced_text = substitution.gsub(/\\(\d+|k<[^>]+>)/) do |ref|
          key = ref[1..] # remove leading '\'

          if key.start_with?("k<")
            name = key[2..-2]
            match_data.named_captures[name] || ""
          else
            index = key.to_i
            match_data[index] || ""
          end
        rescue => e
          matched_text # fallback to original text if any error
        end

        changed = true if replaced_text != matched_text
        content = replaced_text.empty? ? "" : ERB::Util.h(replaced_text)
        %Q(<mark class="bg-green-300 p-0.5 rounded-xs text-green-900">#{content}</mark>)
      end

      @substitution_result = test_string unless changed
      @substitution_result = @substitution_result.html_safe if @substitution_result.respond_to?(:html_safe)
      @substitution_result
    end

    private

    def validate_capture_references
      return if @regexp.nil? || substitution.blank?

      numbered_refs = substitution.scan(/\\(\d+)/).flatten.map(&:to_i)
      named_refs = substitution.scan(/\\k<([^>]+)>/).flatten

      match = test_string.match(@regexp)
      valid_groups = match&.captures&.size.to_i
      valid_names = match&.names || []

      if numbered_refs.any?
        max_ref = numbered_refs.max
        if max_ref > valid_groups
          errors.add(:substitution, "References non-existent numbered capture group(s): (\\#{max_ref})")
        end
      end

      invalid_names = named_refs.reject { |name| valid_names.include?(name) }
      if invalid_names.any?
        errors.add(:substitution, "References non-existent named capture group(s): #{invalid_names.join(', ')}")
      end
    end
  end
end
