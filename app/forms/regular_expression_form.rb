class RegularExpressionForm
  include ActiveModel::Model

  attr_accessor :expression, :test_string, :options, :substitution

  validates :expression, presence: true
  validates :test_string, presence: true

  validate :check_expression

  attr_reader :match_data, :elapsed_time_ms, :average_elapsed_time_ms,
              :match_success, :diagram_error_message,
              :substitution_result, :substitution_positions

  def unready?
    expression.blank? || test_string.blank?
  end

  def named_captures
    return [] if unready? || regexp.nil? || regexp.named_captures.empty?

    results = []
    test_string.to_enum(:scan, regexp).each do
      match = Regexp.last_match
      captures_hash = {}

      regexp.named_captures.each do |name, _|
        captures_hash[name] = match[name] unless match[name].nil?
      end

      results << captures_hash unless captures_hash.empty?
    end

    results
  end

  def captures
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

    regexp.names.any? ? named_captures : captures
  end

  def match_positions
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
    return nil if expression.blank?

    renderer = RegexpDiagramRenderer.new(expression: expression, options: options)
    svg = renderer.render
    @diagram_error_message = renderer.error_message
    svg
  end

  def perform_substitution
    return nil if unready? || regexp.nil? || substitution.nil?

    substitutor = RegexpSubstitutor.new(regexp:, test_string:, substitution:)
    @substitution_result = substitutor.perform
  end

  def ruby_code_snippet
    return nil if unready? || regexp.nil?

    generator = RegexpCodeGenerator.new(regexp:, test_string:, substitution:)
    generator.generate
  end

  private

  def regexp
    return @regexp if defined?(@regexp)

    @regexp = Regexp.new(expression, parse_options)
  rescue RegexpError => e
    errors.add(:base, "#{e.message}")
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

  def check_expression
    return if unready?

    if regexp.nil?
      errors.add(:base, "Invalid regular expression")
      return
    end

    times = []
    last_match = nil
    match_result = false

    5.times do
      start_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      last_match = regexp.match(test_string)
      match_result = !last_match.nil?
      end_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      times << (end_time - start_time)
    end

    @elapsed_time_ms = (times.last * 1000).round(3)
    @average_elapsed_time_ms = (times.sum / times.size * 1000).round(3)
    @match_success = match_result
    @match_data = last_match
  end
end
