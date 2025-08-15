class RegularExpression
  include ActiveModel::Model

  attr_accessor :expression, :test_string, :options

  validate :check_expression

  attr_reader :match_data, :elapsed_time_ms, :average_elapsed_time_ms, :match_success, :diagram_error_message

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

    positions = []
    test_string.to_enum(:scan, regexp).each_with_index do |_, i|
      match = Regexp.last_match
      positions << {
        start: match.begin(0),
        end: match.end(0),
        index: i,
        invisible: invisible_match?(match)
      }
    end

    positions
  rescue RegexpError
    []
  end

  def invisible_match?(match)
    match[0].match?(/\A\s/) || match[0].match?(/\z/) || match[0].match?(/\s/)
  end

  def diagram_svg
    return nil if expression.blank?

    begin
      @diagram_error_message = nil
      raw_svg = RegexpDiagram.create_svg_from_regex(expression, options: options)

      ActionController::Base.helpers.sanitize(
        raw_svg,
        tags: %w[
          svg g path rect circle line text style defs title desc
        ],
        attributes: %w[
          d fill stroke x y cx cy r width height viewBox xmlns class type
          transform text-anchor font stroke-width rx ry
        ],
        scrubber: nil
      )
    rescue => e
      @diagram_error_message = "Invalid Pattern: #{e.message}"
      nil
    end
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
    return if unready? || regexp.nil?

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
