class RegularExpressionsController < ApplicationController
  def index
    @regular_expression = RegularExpression.new
    @svg_output = nil
  end

  def create
    @regular_expression = RegularExpression.new(regular_expression_params)

    if @regular_expression.expression.present?
      begin
        @svg_output = RegexpDiagram.create_svg_from_regex(@regular_expression.expression)
      rescue StandardError => e
        @svg_output = generate_error_svg("Invalid pattern")
        Rails.logger.error("SVG generation error: #{e.message}")
      end
    else
      @svg_output = nil
    end

    render :index
  end

  private

  def regular_expression_params
    params.require(:regular_expression).permit(:expression, :test_string, :options)
  end

  def generate_error_svg(message)
    "<svg width='400' height='100' xmlns='http://www.w3.org/2000/svg'>
      <rect width='100%' height='100%' fill='#fee2e2'/>
      <text x='50%' y='50%' dominant-baseline='middle' text-anchor='middle' fill='#b91c1c' font-size='16'>
        #{ERB::Util.html_escape(message)}
      </text>
    </svg>"
  end
end
