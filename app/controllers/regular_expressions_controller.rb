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

  # GET /regular_expressions/examples?category=:slug
  # Returns HTML fragment for the requested category's examples (rendering the _category_items partial).
  def examples
    # If caller asked for a random example, return JSON for a random example
    if params[:random].present?
      e = RegularExpression::Example.random_example
      if e.present?
        render json: e
      else
        head :no_content
      end
      return
    end

    cat = params[:category].to_s
    data = RegularExpression::Example.examples_for_category(cat)

    if data.present?
      render partial: "regular_expressions/category_items", locals: { category_key: cat, examples: data[:examples] }
    else
      render plain: "", status: :no_content
    end
  end

  private

  def regular_expression_params
    params.require(:regular_expression).permit(:regular_expression, :test_string, :options, :substitution_string)
  end
end
