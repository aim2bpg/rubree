class RegularExpressionsController < ApplicationController
  def index
    @regular_expression = RegularExpression.new
  end

  def create
    @regular_expression = RegularExpression.new(expression: regexp_params[:expression], test_string: regexp_params[:test_string])

    render :index
  end

  private

  def regexp_params
    params
      .require(:regular_expression)
      .permit(:expression, :test_string)
  end
end
