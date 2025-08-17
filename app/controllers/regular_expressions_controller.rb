class RegularExpressionsController < ApplicationController
  def index
    @regular_expression = RegularExpression.new
    @svg_output = nil
    @diagram_error_message = nil
  end

  def create
    @regular_expression = RegularExpression.new(regular_expression_params)

    @svg_output = @regular_expression.diagram_svg
    @diagram_error_message = @regular_expression.diagram_error_message

    if params[:regular_expression][:substitution].present?
      @regular_expression.perform_substitution
    end

    render :index
  end

  private

  def regular_expression_params
    params.require(:regular_expression).permit(:expression, :test_string, :options, :substitution)
  end
end
