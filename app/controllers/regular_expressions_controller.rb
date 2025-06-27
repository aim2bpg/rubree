class RegularExpressionsController < ApplicationController
  def index
    @regular_expression = RegularExpression.new
  end

  def create
    @regular_expression = RegularExpression.new(regular_expression_params)
    render :index
  end

  private

  def regular_expression_params
    params.require(:regular_expression).permit(:expression, :test_string)
  end
end
