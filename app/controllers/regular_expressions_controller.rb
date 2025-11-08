class RegularExpressionsController < ApplicationController
  def index
    @regular_expression = RegularExpression.new
    @svg_output = nil
    @diagram_error_message = nil
  end

  def create
    begin
      @regular_expression = RegularExpression.new(regular_expression_params)

      @regular_expression.display_captures

      @svg_output = @regular_expression.diagram_svg
      @diagram_error_message = @regular_expression.diagram_error_message

      if params[:regular_expression][:substitution_string].present?
        @regular_expression.substitute
      end

      render :index
    rescue StandardError => e
      @regular_expression ||= RegularExpression.new(regular_expression_params)
      @regular_expression.errors.add(:base, e.message)
      @svg_output = nil
      @diagram_error_message = nil
      render :index
    end
  end

  private

  def regular_expression_params
    params.require(:regular_expression).permit(:regular_expression, :test_string, :options, :substitution_string)
  end
end
