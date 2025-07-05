module RegexpDiagram
  module_function

  def create_svg_from_regex(regexp_str)
    begin
      regex = Regexp.new(regexp_str)
      ast = Regexp::Parser.parse(regex.source)

      diagram_body = ast_to_railroad(ast)
      diagram = RailroadDiagrams::Diagram.new(diagram_body)

      svg_io = StringIO.new
      diagram.write_svg(svg_io.method(:<<))
      svg_io.string
    rescue StandardError => e
      "<!-- Error generating diagram: #{e.message} -->"
    end
  end

  def ast_to_railroad(ast)
    case ast
    when Regexp::Expression::Quantifier
      base = ast_to_railroad(ast.base)
      wrap_with_quantifier(base, ast.quantifier)

    when Regexp::Expression::Root, Regexp::Expression::Sequence
      RailroadDiagrams::Sequence.new(*ast.expressions.map { |e| ast_to_railroad(e) })

    when Regexp::Expression::Alternative, Regexp::Expression::Alternation
      RailroadDiagrams::Choice.new(0, *ast.expressions.map { |e| ast_to_railroad(e) })

    when Regexp::Expression::Group::Capture
      group_content = ast_to_railroad_sequence(ast.expressions)
      group = RailroadDiagrams::Group.new(group_content, "キャプチャグループ")
      wrap_with_quantifier(group, ast.quantifier)

    when Regexp::Expression::Group::Passive
      group_content = ast_to_railroad_sequence(ast.expressions)
      group = RailroadDiagrams::Group.new(group_content, "非キャプチャグループ")
      wrap_with_quantifier(group, ast.quantifier)

    when Regexp::Expression::CharacterSet
      label = ast.negative? ? "否定文字セット" : "文字セット"
      expressions = []

      ast.expressions.each do |e|
        if e.is_a?(Regexp::Expression::CharacterSet::Range)
          range_start = e.expressions.first.text
          range_end = e.expressions.last.text

          # 範囲の処理：`a-z`のような範囲をそのまま表示
          expressions << RailroadDiagrams::Sequence.new(
            RailroadDiagrams::Terminal.new(range_start),
            RailroadDiagrams::NonTerminal.new("-"),
            RailroadDiagrams::Terminal.new(range_end)
          )
        else
          expressions << ast_to_railroad(e)
        end
      end

      wrap_with_quantifier(RailroadDiagrams::MultipleChoice.new(0, "any", *expressions, RailroadDiagrams::Comment.new(label)), ast.quantifier)

    when Regexp::Expression::Literal, Regexp::Expression::Escape
      wrap_with_quantifier(RailroadDiagrams::Terminal.new(ast.text), ast.quantifier)

    when Regexp::Expression::CharacterType::Digit
      wrap_with_quantifier(RailroadDiagrams::NonTerminal.new("digit"), ast.quantifier)

    when Regexp::Expression::CharacterType::Word
      wrap_with_quantifier(RailroadDiagrams::NonTerminal.new("単語 \\w"), ast.quantifier)

    when Regexp::Expression::CharacterType::Space
      wrap_with_quantifier(RailroadDiagrams::NonTerminal.new("空白 \\s"), ast.quantifier)

    when Regexp::Expression::Anchor::BeginningOfLine
      wrap_with_quantifier(RailroadDiagrams::NonTerminal.new("行頭 ^"), ast.quantifier)

    when Regexp::Expression::Anchor::EndOfLine
      wrap_with_quantifier(RailroadDiagrams::NonTerminal.new("行末 $"), ast.quantifier)

    when Regexp::Expression::Anchor::WordBoundary
      wrap_with_quantifier(RailroadDiagrams::NonTerminal.new("単語境界 \\b"), ast.quantifier)

    when Regexp::Expression::Anchor::NonWordBoundary
      wrap_with_quantifier(RailroadDiagrams::NonTerminal.new("非単語境界 \\B"), ast.quantifier)

    when Regexp::Expression::Comment
      wrap_with_quantifier(RailroadDiagrams::Comment.new(ast.text), ast.quantifier)

    else
      wrap_with_quantifier(RailroadDiagrams::Terminal.new(ast.text.to_s), ast.quantifier)
    end
  end

  def ast_to_railroad_sequence(expressions)
    RailroadDiagrams::Sequence.new(*expressions.map { |e| ast_to_railroad(e) })
  end

  def wrap_with_quantifier(base, quant)
    return base unless quant

    quant = quant.to_s

    case quant
    when "*"
      RailroadDiagrams::ZeroOrMore.new(base, RailroadDiagrams::Comment.new("0回以上"))
    when "+"
      RailroadDiagrams::OneOrMore.new(base, RailroadDiagrams::Comment.new("1回以上"))
    when "?"
      RailroadDiagrams::Optional.new(base, RailroadDiagrams::Comment.new("0回または1回"))
    when /\A\{(\d+)\}\z/
      n = $1.to_i
      if n > 0
        RailroadDiagrams::OneOrMore.new(base, RailroadDiagrams::Comment.new("#{n}回"))
      else
        RailroadDiagrams::Optional.new(base, RailroadDiagrams::Comment.new("#{n}回"))
      end
    when /\A\{(\d+),(\d*)\}\z/
      min = $1.to_i
      max = $2.empty? ? nil : $2.to_i
      if max
        RailroadDiagrams::OneOrMore.new(base, RailroadDiagrams::Comment.new("#{min}〜#{max}回"))
      else
        RailroadDiagrams::ZeroOrMore.new(base, RailroadDiagrams::Comment.new("#{min}回以上"))
      end
    else
      RailroadDiagrams::Group.new(base, "量指定子: #{quant}")
    end
  end
end
