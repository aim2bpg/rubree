class RegularExpression
  class RailroadDiagramRenderer
    include ActiveModel::Model

    attr_accessor :regular_expression, :options
    attr_reader :error_message

    def initialize(regular_expression:, options: nil)
      @regular_expression = regular_expression
      @options = options
      @error_message = nil
    end

    def render
      return nil if regular_expression.blank?

      raw_svg = RegularExpression::RailroadDiagramGenerator.create_svg_from_regex(regular_expression, options: options)
      self.class.sanitize_svg(raw_svg)
    rescue => e
      @error_message = "Invalid pattern: #{e.message}"
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
        ]
      )
    end
  end
end
