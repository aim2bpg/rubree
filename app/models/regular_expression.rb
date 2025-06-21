class RegularExpression
  include ActiveModel::Model

  # 正規表現のパターン文字列
  attr_reader :expression

  # 正規表現をかける対象となる文字列
  attr_reader :test_string

  validate :check_expression

  def initialize(expression: '', test_string: '')
    @expression = expression
    @test_string = test_string
  end

  # 画面が初期表示、未入力の状態であるかを判定するのに使用。
  def unready?
    @expression.blank? || @test_string.blank?
  end

  private

  def regexp
    @regexp ||= Regexp.new(expression)
  end

  # この結果を正規表現の判定結果として表示している
  def check_expression
    return if regexp.match?(test_string)

    errors.add(:base, :invalid, message: '一致しませんでした...')
  end
end
