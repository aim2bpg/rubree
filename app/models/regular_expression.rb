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

  def highlighted_test_string
    return CGI.escapeHTML(test_string) if unready?

    matches = []
    regexp = Regexp.new(expression)

    test_string.to_enum(:scan, regexp).each_with_index do |_, i|
      match = Regexp.last_match
      matches << {
        start: match.begin(0),
        end: match.end(0),
        text: match[0],
        index: i
      }
    end

    return CGI.escapeHTML(test_string) if matches.empty?

    highlighted = ""
    last_index = 0

    matches.each do |m|
      highlighted += CGI.escapeHTML(test_string[last_index...m[:start]])
      highlighted += "<mark>"
      highlighted += CGI.escapeHTML(test_string[m[:start]...m[:end]])
      highlighted += "</mark>"
      last_index = m[:end]
    end

    highlighted += CGI.escapeHTML(test_string[last_index..-1]) if last_index < test_string.length
    highlighted
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
