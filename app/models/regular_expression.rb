class RegularExpression
  include ActiveModel::Model

  attr_accessor :expression, :test_string

  validate :check_expression

  attr_reader :match_data, :elapsed_time_ms, :average_elapsed_time_ms, :match_success

  def unready?
    expression.blank? || test_string.blank?
  end

  def named_captures
    return {} if unready? || !match_data
    regexp.named_captures.transform_values { |indexes| indexes.map { |i| match_data[i] }.first }
  end

  def captures
    return [] if unready? || !match_data
    regexp.names.empty? ? match_data.captures : []
  end

  def match_positions
    return [] if unready?

    positions = []
    regexp = Regexp.new(expression)

    test_string.to_enum(:scan, regexp).each_with_index do |_, i|
      match = Regexp.last_match
      positions << { start: match.begin(0), end: match.end(0), index: i }
    end

    positions
  rescue RegexpError
    []
  end

  def diagram_svg
    return nil if unready?

    raw_svg = RegexpDiagram.create_svg_from_regex(expression)

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
    ).html_safe
  rescue StandardError => e
    "<!-- Error generating diagram: #{ERB::Util.html_escape(e.message)} -->".html_safe
  end

  private

  def regexp
    @regexp ||= Regexp.new(expression)
  rescue RegexpError => e
    errors.add(:base, "Invalid regular expression syntax: #{e.message}")
    Regexp.new("")
  end

  def check_expression
    return if unready?

    times = []
    result = nil

    5.times do
      start_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      result = regexp.match(test_string)
      end_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      times << (end_time - start_time)
    end

    @elapsed_time_ms = (times.last * 1000).round(3)
    @average_elapsed_time_ms = (times.sum / times.size * 1000).round(3)
    @match_data = result
    @match_success = !!@match_data

    errors.add(:base, "No match found...") unless @match_success
  end
end
