class RegexpSubstitutor
  attr_reader :regexp, :test_string, :substitution, :substitution_result

  def initialize(regexp:, test_string:, substitution:)
    @regexp = regexp
    @test_string = test_string
    @substitution = substitution
    @substitution_result = nil
  end

  def perform
    return nil if regexp.nil? || test_string.nil? || substitution.nil?

    if substitution.match?(/\\\d+/)
      test_string.match(regexp)
      valid_groups = Regexp.last_match&.captures&.size.to_i

      max_ref = substitution.scan(/\\(\d+)/).flatten.map(&:to_i).max.to_i
      if max_ref > valid_groups
        @substitution_result = test_string
        return @substitution_result
      end
    end

    @substitution_result = test_string.gsub(regexp) do |matched_text|
      begin
        replaced_text = matched_text.gsub(regexp, substitution)
      rescue ArgumentError
        replaced_text = matched_text
      end

      content = replaced_text.empty? ? "" : ERB::Util.h(replaced_text)
      %Q(<mark class="bg-green-300 p-0.5 rounded-xs text-green-900">#{content}</mark>)
    end.html_safe

    @substitution_result
  rescue => e
    @substitution_result = test_string
  end

  def self.perform_substitution(expression, test_string, substitution, _unused = nil)
    regexp = Regexp.new(expression) rescue nil
    return nil unless regexp

    new(regexp: regexp, test_string: test_string, substitution: substitution).perform
  rescue
    nil
  end
end
