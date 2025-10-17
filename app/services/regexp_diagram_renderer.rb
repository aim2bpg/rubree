class RegexpDiagramRenderer
  attr_reader :expression, :options, :error_message

  def initialize(expression:, options: nil)
    @expression = expression
    @options = options
    @error_message = nil
  end

  def render
    return nil if expression.blank?

    raw_svg = RegexpDiagramGenerator.create_svg_from_regex(expression, options: options)
    self.class.sanitize_svg(raw_svg)
  rescue => e
    @error_message = "Invalid Pattern: #{e.message}"
    nil
  end

  def self.sanitize_svg(raw_svg)
    return "" if raw_svg.to_s.strip.empty?

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
  end
end
