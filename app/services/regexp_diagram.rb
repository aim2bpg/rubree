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
      puts "[ERROR] #{e.class}: #{e.message}"
      puts e.backtrace
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

    when Regexp::Expression::Assertion::Lookahead
      group_content = ast_to_railroad_sequence(ast.expressions)
      label = "positive lookahead"
      wrap_with_quantifier(RailroadDiagrams::Group.new(group_content, label), ast.quantifier)

    when Regexp::Expression::Assertion::NegativeLookahead
      group_content = ast_to_railroad_sequence(ast.expressions)
      label = "negative lookahead"
      wrap_with_quantifier(RailroadDiagrams::Group.new(group_content, label), ast.quantifier)

    when Regexp::Expression::Assertion::Lookbehind
      group_content = ast_to_railroad_sequence(ast.expressions)
      label = "positive lookbehind"
      wrap_with_quantifier(RailroadDiagrams::Group.new(group_content, label), ast.quantifier)

    when Regexp::Expression::Assertion::NegativeLookbehind
      group_content = ast_to_railroad_sequence(ast.expressions)
      label = "negative lookbehind"
      wrap_with_quantifier(RailroadDiagrams::Group.new(group_content, label), ast.quantifier)

    when Regexp::Expression::Group::Atomic
      group_content = ast_to_railroad_sequence(ast.expressions)
      label = "atomic group"
      wrap_with_quantifier(RailroadDiagrams::Group.new(group_content, label), ast.quantifier)

    when Regexp::Expression::Group::Absence
      group_content = ast_to_railroad_sequence(ast.expressions)
      label = "absence group"
      wrap_with_quantifier(RailroadDiagrams::Group.new(group_content, label), ast.quantifier)

    when Regexp::Expression::Group::Named
      group_content = ast_to_railroad_sequence(ast.expressions)
      label = ast.name ? "#{ast.name}" : "named group"
      wrap_with_quantifier(RailroadDiagrams::Group.new(group_content, label), ast.quantifier)

    when Regexp::Expression::Group::Capture
      group_content = ast_to_railroad_sequence(ast.expressions)
      label = ast.number ? "group ##{ast.number}" : "capture group"
      wrap_with_quantifier(RailroadDiagrams::Group.new(group_content, label), ast.quantifier)

    when Regexp::Expression::Group::Options
      group_content = ast_to_railroad_sequence(ast.expressions)
      label = "options group (#{ast.text})"
      wrap_with_quantifier(RailroadDiagrams::Group.new(group_content, label), ast.quantifier)

    when Regexp::Expression::Group::Passive
      group_content = ast_to_railroad_sequence(ast.expressions)
      label = "non-capturing group"
      wrap_with_quantifier(RailroadDiagrams::Group.new(group_content, label), ast.quantifier)

    when Regexp::Expression::CharacterSet
      label = ast.negative? ? "negated character set" : "character set"
      expressions = ast.expressions.map do |e|
        if e.is_a?(Regexp::Expression::CharacterSet::Range)
          start = e.expressions.first.text
          ending = e.expressions.last.text
          RailroadDiagrams::Sequence.new(RailroadDiagrams::NonTerminal.new("\"#{start}\" - \"#{ending}\""))
        else
          ast_to_railroad(e)
        end
      end

      wrap_with_quantifier(
        RailroadDiagrams::MultipleChoice.new(0, "any", *expressions, RailroadDiagrams::Comment.new(label)),
        ast.quantifier
      )

    when Regexp::Expression::Anchor::BeginningOfLine
      wrap_with_quantifier(RailroadDiagrams::NonTerminal.new("beginning of line"), ast.quantifier)

    when Regexp::Expression::Anchor::EndOfLine
      wrap_with_quantifier(RailroadDiagrams::NonTerminal.new("end of line"), ast.quantifier)

    when Regexp::Expression::Anchor::BeginningOfString
      wrap_with_quantifier(RailroadDiagrams::NonTerminal.new("beginning of string"), ast.quantifier)

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

    # when Regexp::Expression::Backreference::NumberRecursionLevel
    #   label = "backreference number recursion level"
    #   label += " \\g<#{ast.number}>" if ast.respond_to?(:number)
    #   wrap_with_quantifier(RailroadDiagrams::NonTerminal.new(label), ast.quantifier)

    # when Regexp::Expression::Backreference::NumberCallRelative
    #   label = "backreference number call relative"
    #   label += " \\g<#{ast.token.text}>" if ast.respond_to?(:token)
    #   wrap_with_quantifier(RailroadDiagrams::NonTerminal.new(label), ast.quantifier)

    # when Regexp::Expression::Backreference::NumberRelative
    #   label = "backreference number relative"
    #   label += " \\g<#{ast.token.text}>" if ast.respond_to?(:token)
    #   wrap_with_quantifier(RailroadDiagrams::NonTerminal.new(label), ast.quantifier)

    when Regexp::Expression::Backreference::NumberCall
      label = "backreference number call"
      label += " \\g<#{ast.number}>" if ast.respond_to?(:number)
      wrap_with_quantifier(RailroadDiagrams::NonTerminal.new(label), ast.quantifier)

    when Regexp::Expression::Backreference::Number
      label = "backreference number"
      label += " \\#{ast.number}" if ast.respond_to?(:number)
      wrap_with_quantifier(RailroadDiagrams::NonTerminal.new(label), ast.quantifier)

    # when Regexp::Expression::Backreference::NameCallRelative
    #   label = "backreference name call relative"
    #   label += " \\g<#{ast.name}>" if ast.respond_to?(:name)
    #   wrap_with_quantifier(RailroadDiagrams::NonTerminal.new(label), ast.quantifier)

    when Regexp::Expression::Backreference::NameCall
      label = "backreference name call"
      label += " \\g<#{ast.name}>" if ast.respond_to?(:name)
      wrap_with_quantifier(RailroadDiagrams::NonTerminal.new(label), ast.quantifier)

    when Regexp::Expression::Backreference::Name
      label = "backreference name"
      label += " \\k<#{ast.name}>" if ast.respond_to?(:name)
      wrap_with_quantifier(RailroadDiagrams::NonTerminal.new(label), ast.quantifier)

    # when Regexp::Expression::Backreference::NameRecursionLevel
    #   label = "backreference name recursion level"
    #   label += " \\k<#{ast.name}>" if ast.respond_to?(:name)
    #   wrap_with_quantifier(RailroadDiagrams::NonTerminal.new(label), ast.quantifier)

    when Regexp::Expression::CharacterType::Any
      wrap_with_quantifier(RailroadDiagrams::NonTerminal.new("any character"), ast.quantifier)

    when Regexp::Expression::CharacterType::Digit
      wrap_with_quantifier(RailroadDiagrams::NonTerminal.new("digit"), ast.quantifier)

    when Regexp::Expression::CharacterType::NonDigit
      wrap_with_quantifier(RailroadDiagrams::NonTerminal.new("non-digit"), ast.quantifier)

    when Regexp::Expression::CharacterType::Hex
      wrap_with_quantifier(RailroadDiagrams::NonTerminal.new("hex character"), ast.quantifier)

    when Regexp::Expression::CharacterType::NonHex
      wrap_with_quantifier(RailroadDiagrams::NonTerminal.new("non-hex character"), ast.quantifier)

    when Regexp::Expression::CharacterType::Word
      wrap_with_quantifier(RailroadDiagrams::NonTerminal.new("word character"), ast.quantifier)

    when Regexp::Expression::CharacterType::NonWord
      wrap_with_quantifier(RailroadDiagrams::NonTerminal.new("non-word character"), ast.quantifier)

    when Regexp::Expression::CharacterType::Space
      wrap_with_quantifier(RailroadDiagrams::NonTerminal.new("whitespace"), ast.quantifier)

    when Regexp::Expression::CharacterType::NonSpace
      wrap_with_quantifier(RailroadDiagrams::NonTerminal.new("non-whitespace"), ast.quantifier)

    when Regexp::Expression::CharacterType::Linebreak
      wrap_with_quantifier(RailroadDiagrams::NonTerminal.new("line break"), ast.quantifier)

    when Regexp::Expression::CharacterType::ExtendedGrapheme
      wrap_with_quantifier(RailroadDiagrams::NonTerminal.new("extended grapheme"), ast.quantifier)

    when Regexp::Expression::Comment
      RailroadDiagrams::Comment.new(ast.text)

    when Regexp::Expression::FreeSpace
      RailroadDiagrams::Comment.new("whitespace")

    when Regexp::Expression::Keep::Mark
      wrap_with_quantifier(RailroadDiagrams::NonTerminal.new(ast.text), ast.quantifier)

    when Regexp::Expression::Literal
      wrap_with_quantifier(RailroadDiagrams::Terminal.new("\"#{ast.text}\""), ast.quantifier)

    when Regexp::Expression::PosixClass
      wrap_with_quantifier(RailroadDiagrams::NonTerminal.new(ast.text), ast.quantifier)

    when Regexp::Expression::UnicodeProperty::Base
      wrap_with_quantifier(RailroadDiagrams::NonTerminal.new(ast.text), ast.quantifier)

    when Regexp::Expression::WhiteSpace
      RailroadDiagrams::NonTerminal.new("whitespace")

    when Regexp::Expression::EscapeSequence::AsciiEscape
      wrap_with_quantifier(RailroadDiagrams::NonTerminal.new("ASCII escape"), ast.quantifier)

    when Regexp::Expression::EscapeSequence::Backspace
      wrap_with_quantifier(RailroadDiagrams::NonTerminal.new("backspace"), ast.quantifier)

    when Regexp::Expression::EscapeSequence::Bell
      wrap_with_quantifier(RailroadDiagrams::NonTerminal.new("bell"), ast.quantifier)

    when Regexp::Expression::EscapeSequence::FormFeed
      wrap_with_quantifier(RailroadDiagrams::NonTerminal.new("form feed"), ast.quantifier)

    when Regexp::Expression::EscapeSequence::Newline
      wrap_with_quantifier(RailroadDiagrams::NonTerminal.new("newline"), ast.quantifier)

    when Regexp::Expression::EscapeSequence::Return
      wrap_with_quantifier(RailroadDiagrams::NonTerminal.new("carriage return"), ast.quantifier)

    when Regexp::Expression::EscapeSequence::Tab
      wrap_with_quantifier(RailroadDiagrams::NonTerminal.new("tab"), ast.quantifier)

    when Regexp::Expression::EscapeSequence::VerticalTab
      wrap_with_quantifier(RailroadDiagrams::NonTerminal.new("vertical tab"), ast.quantifier)

    when Regexp::Expression::EscapeSequence::Literal
      cleaned_text = ast.text.gsub("\\", "")
      wrap_with_quantifier(RailroadDiagrams::Terminal.new("\"#{cleaned_text}\""), ast.quantifier)

    when Regexp::Expression::EscapeSequence::Octal
      wrap_with_quantifier(RailroadDiagrams::NonTerminal.new("octal"), ast.quantifier)

    when Regexp::Expression::EscapeSequence::Hex
      wrap_with_quantifier(RailroadDiagrams::NonTerminal.new("hex"), ast.quantifier)

    when Regexp::Expression::EscapeSequence::Codepoint
      wrap_with_quantifier(RailroadDiagrams::NonTerminal.new("codepoint"), ast.quantifier)

    when Regexp::Expression::EscapeSequence::CodepointList
      wrap_with_quantifier(RailroadDiagrams::NonTerminal.new("codepoint list"), ast.quantifier)

    when Regexp::Expression::EscapeSequence::UTF8Hex
      wrap_with_quantifier(RailroadDiagrams::NonTerminal.new("UTF-8 hex"), ast.quantifier)

    when Regexp::Expression::EscapeSequence::AbstractMetaControlSequence
      wrap_with_quantifier(RailroadDiagrams::NonTerminal.new("abstract meta control"), ast.quantifier)

    when Regexp::Expression::EscapeSequence::Control
      wrap_with_quantifier(RailroadDiagrams::NonTerminal.new("control character"), ast.quantifier)

    when Regexp::Expression::EscapeSequence::Meta
      wrap_with_quantifier(RailroadDiagrams::NonTerminal.new("meta character"), ast.quantifier)

    when Regexp::Expression::EscapeSequence::MetaControl
      wrap_with_quantifier(RailroadDiagrams::NonTerminal.new("meta control"), ast.quantifier)

    else
      wrap_with_quantifier(RailroadDiagrams::Terminal.new("\"#{ast.text}\""), ast.quantifier)
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
