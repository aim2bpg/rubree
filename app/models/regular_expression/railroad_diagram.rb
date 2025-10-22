require_relative "./railroad_diagram_builder"

class RegularExpression
  class RailroadDiagram
    include ActiveModel::Model

    attr_accessor :regular_expression, :options
    attr_reader :error_message

    validates :regular_expression, presence: true
    validate :check_for_lazy_or_possessive_quantifiers

    def initialize(regular_expression:, options: nil)
      @regular_expression = regular_expression
      @options = options
      @error_message = nil
    end

    def generate
      return nil if regular_expression.nil? || regular_expression == ""

      if regular_expression.match?(/\{\d*,?\d*\}[?+]/)
        raise ArgumentError, "Skipped: Lazy or possessive quantifier in range (e.g. {1,3}? or {2,}+)"
      end

      regex_options = self.class.parse_options(options)
      Regexp.new(regular_expression, regex_options)

      ast = Regexp::Parser.parse(regular_expression, options: regex_options)
      diagram_body = RegularExpression::RailroadDiagramBuilder.ast_to_railroad(ast)
      diagram = RailroadDiagrams::Diagram.new(diagram_body)

      svg_io = StringIO.new
      diagram.write_svg(svg_io.method(:<<))
      raw_svg = svg_io.string

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

    def self.parse_options(option_str)
      return 0 if option_str.blank?

      option_map = {
        "i" => Regexp::IGNORECASE,
        "m" => Regexp::MULTILINE,
        "x" => Regexp::EXTENDED
      }

      option_str.downcase.chars.map { |opt| option_map[opt] }.compact.inject(0, :|)
    end
  end
end
