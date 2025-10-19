class RegularExpression
  include ActiveModel::Model

  attr_accessor :regular_expression, :test_string, :options, :substitution

  validates :regular_expression, presence: true
  validates :test_string, presence: true

  validate :validate_regular_expression

  attr_reader :match_data, :elapsed_time_ms, :average_elapsed_time_ms,
              :match_success, :diagram_error_message,
              :substitution_result

  def unready?
    regular_expression.blank? || test_string.blank?
  end

  def named_capture_groups
    return [] if unready? || regexp.nil? || regexp.named_captures.empty?

    results = []
    test_string.to_enum(:scan, regexp).each do
      match = Regexp.last_match
      captures_hash = {}

      regexp.named_captures.each_key do |name|
        captures_hash[name] = match[name] if match[name]
      end

      results << captures_hash unless captures_hash.empty?
    end

    results
  end

  def capture_groups
    return [] if unready? || regexp.nil?

    results = []
    test_string.to_enum(:scan, regexp).each do
      match = Regexp.last_match
      next if match.captures.empty?
      results << match.captures
    end

    results
  end

  def display_captures
    return [] if unready? || regexp.nil?

    captures = regexp.names.any? ? named_capture_groups : capture_groups
    captures.flatten.map do |capture|
      if capture.is_a?(String)
        "<mark class=\"bg-green-300 p-0.5 rounded-xs text-green-900\">#{capture}</mark>"
      else
        capture
      end
    end
  end

  def match_spans
    return [] if unready? || regexp.nil?

    test_string.to_enum(:scan, regexp).map.with_index do |_, i|
      match = Regexp.last_match
      {
        start: match.begin(0),
        end: match.end(0),
        index: i,
        invisible: true
      }
    end
  rescue RegexpError
    []
  end

  def diagram_svg
    return nil if regular_expression.blank?

    renderer = RegularExpression::RailroadDiagramRenderer.new(regular_expression:, options:)
    svg = renderer.render
    @diagram_error_message = renderer.error_message
    svg
  end

  def substitute
    return nil if unready? || regexp.nil? || substitution.nil?

    substitutor = RegularExpression::Substitutor.new(
      regular_expression: regexp,
      test_string: test_string,
      substitution: substitution
    )
    @substitution_result = substitutor.perform
  end

  def ruby_code
    return nil if unready? || regexp.nil?

    generator = RegularExpression::RubyCodeGenerator.new(
      regular_expression: regexp,
      test_string: test_string,
      substitution: substitution
    )
    generator.generate
  end

  private

  def regexp
    return @regexp if defined?(@regexp)

    @regexp = Regexp.new(regular_expression, parse_options)
  rescue RegexpError => e
    errors.add(:base, e.message)
    @regexp = nil
  end

  def parse_options
    return 0 if options.blank?

    option_map = {
      "i" => Regexp::IGNORECASE,
      "m" => Regexp::MULTILINE,
      "x" => Regexp::EXTENDED
    }

    options.downcase.chars.map { |opt| option_map[opt] }.compact.inject(0, :|)
  end

  def validate_regular_expression
    return if unready?

    if regexp.nil?
      errors.add(:base, "Invalid regular expression")
      return
    end

    times = []
    last_match = nil
    matched = false

    5.times do
      start_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      last_match = regexp.match(test_string)
      matched = !last_match.nil?
      end_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      times << (end_time - start_time)
    end

    @elapsed_time_ms = (times.last * 1000).round(3)
    @average_elapsed_time_ms = (times.sum / times.size * 1000).round(3)
    @match_success = matched
    @match_data = last_match
  end
end
