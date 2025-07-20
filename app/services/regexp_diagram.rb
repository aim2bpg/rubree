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
      group = RailroadDiagrams::Group.new(group_content, "capture group")
      wrap_with_quantifier(group, ast.quantifier)

    when Regexp::Expression::Group::Passive
      group_content = ast_to_railroad_sequence(ast.expressions)
      group = RailroadDiagrams::Group.new(group_content, "non-capture group")
      wrap_with_quantifier(group, ast.quantifier)

    when Regexp::Expression::CharacterSet
      label = ast.negative? ? "non-character set" : "character set"
      expressions = []

      ast.expressions.each do |e|
        if e.is_a?(Regexp::Expression::CharacterSet::Range)
          range_start = e.expressions.first.text
          range_end = e.expressions.last.text

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

    when Regexp::Expression::CharacterType::Any
      wrap_with_quantifier(RailroadDiagrams::NonTerminal.new("any"), ast.quantifier)

    when Regexp::Expression::CharacterType::Digit
      wrap_with_quantifier(RailroadDiagrams::NonTerminal.new("digit"), ast.quantifier)

    when Regexp::Expression::CharacterType::NonDigit
      wrap_with_quantifier(RailroadDiagrams::NonTerminal.new("non-digit"), ast.quantifier)

    when Regexp::Expression::CharacterType::Hex
      wrap_with_quantifier(RailroadDiagrams::NonTerminal.new("hex"), ast.quantifier)

    when Regexp::Expression::CharacterType::NonHex
      wrap_with_quantifier(RailroadDiagrams::NonTerminal.new("non-hex"), ast.quantifier)

    when Regexp::Expression::CharacterType::Word
      wrap_with_quantifier(RailroadDiagrams::NonTerminal.new("word"), ast.quantifier)

    when Regexp::Expression::CharacterType::NonWord
      wrap_with_quantifier(RailroadDiagrams::NonTerminal.new("non-word"), ast.quantifier)

    when Regexp::Expression::CharacterType::Space
      wrap_with_quantifier(RailroadDiagrams::NonTerminal.new("white space"), ast.quantifier)

    when Regexp::Expression::CharacterType::NonSpace
      wrap_with_quantifier(RailroadDiagrams::NonTerminal.new("non-white space"), ast.quantifier)

    when Regexp::Expression::CharacterType::Linebreak
      wrap_with_quantifier(RailroadDiagrams::NonTerminal.new("line break"), ast.quantifier)

    when Regexp::Expression::CharacterType::ExtendedGrapheme
      wrap_with_quantifier(RailroadDiagrams::NonTerminal.new("extended grapheme"), ast.quantifier)

    when Regexp::Expression::Anchor::BeginningOfLine
      wrap_with_quantifier(RailroadDiagrams::NonTerminal.new("bigining of line"), ast.quantifier)

    when Regexp::Expression::Anchor::EndOfLine
      wrap_with_quantifier(RailroadDiagrams::NonTerminal.new("end of line"), ast.quantifier)

    when Regexp::Expression::Anchor::BeginningOfString
      wrap_with_quantifier(RailroadDiagrams::NonTerminal.new("begining of string"), ast.quantifier)

    when Regexp::Expression::Anchor::EndOfString
      wrap_with_quantifier(RailroadDiagrams::NonTerminal.new("end of string"), ast.quantifier)

    when Regexp::Expression::Anchor::EndOfStringOrBeforeEndOfLine
      wrap_with_quantifier(RailroadDiagrams::NonTerminal.new("end of string or before end of line"), ast.quantifier)

    when Regexp::Expression::Anchor::WordBoundary
      wrap_with_quantifier(RailroadDiagrams::NonTerminal.new("word boundary"), ast.quantifier)

    when Regexp::Expression::Anchor::NonWordBoundary
      wrap_with_quantifier(RailroadDiagrams::NonTerminal.new("non-word boundary"), ast.quantifier)

    when Regexp::Expression::Anchor::MatchStart
      wrap_with_quantifier(RailroadDiagrams::NonTerminal.new("match start"), ast.quantifier)

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
      RailroadDiagrams::ZeroOrMore.new(base, RailroadDiagrams::Comment.new("0 time or more"))
    when "+"
      RailroadDiagrams::OneOrMore.new(base, RailroadDiagrams::Comment.new("1 time or more"))
    when "?"
      RailroadDiagrams::Optional.new(base, RailroadDiagrams::Comment.new("0 time or 1 time"))
    when /\A\{(\d+)\}\z/
      n = $1.to_i
      if n > 1
        RailroadDiagrams::OneOrMore.new(base, RailroadDiagrams::Comment.new("#{n} times"))
      else
        RailroadDiagrams::Optional.new(base, RailroadDiagrams::Comment.new("#{n} time"))
      end
    when /\A\{(\d+),(\d*)\}\z/
      min = $1.to_i
      max = $2.empty? ? nil : $2.to_i
      if max
        if max > 1
          RailroadDiagrams::OneOrMore.new(base, RailroadDiagrams::Comment.new("#{min}-#{max} times"))
        else
          RailroadDiagrams::OneOrMore.new(base, RailroadDiagrams::Comment.new("#{min}-#{max} time"))
        end
      else
        if min > 1
          RailroadDiagrams::ZeroOrMore.new(base, RailroadDiagrams::Comment.new("#{min} times or more"))
        else
          RailroadDiagrams::ZeroOrMore.new(base, RailroadDiagrams::Comment.new("#{min} time or more"))
        end
      end
    else
      RailroadDiagrams::Group.new(base, "quantifier: #{quant}")
    end
  end
end
