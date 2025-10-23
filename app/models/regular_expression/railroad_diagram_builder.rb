class RegularExpression
  module RailroadDiagramBuilder
    module_function

    LABEL_MAP = {
      Regexp::Expression::Assertion::Lookahead                  => "positive lookahead",
      Regexp::Expression::Assertion::NegativeLookahead          => "negative lookahead",
      Regexp::Expression::Assertion::Lookbehind                 => "positive lookbehind",
      Regexp::Expression::Assertion::NegativeLookbehind         => "negative lookbehind",
      Regexp::Expression::Group::Atomic                         => "atomic group",
      Regexp::Expression::Group::Absence                        => "absence group",
      Regexp::Expression::Group::Passive                        => "non-capturing group"
    }.freeze

    ANCHOR_LABELS = {
      Regexp::Expression::Anchor::BeginningOfLine               => "beginning of line",
      Regexp::Expression::Anchor::EndOfLine                     => "end of line",
      Regexp::Expression::Anchor::BeginningOfString             => "beginning of string",
      Regexp::Expression::Anchor::EndOfString                   => "end of string",
      Regexp::Expression::Anchor::EndOfStringOrBeforeEndOfLine  => "end of string or before end of line",
      Regexp::Expression::Anchor::WordBoundary                  => "word boundary",
      Regexp::Expression::Anchor::NonWordBoundary               => "non-word boundary",
      Regexp::Expression::Anchor::MatchStart                    => "match start"
    }.freeze

    BACKREFERENCE_CLASSES = {
      Regexp::Expression::Backreference::NumberRecursionLevel   => "backreference number recursion level",
      Regexp::Expression::Backreference::NumberCallRelative     => "backreference number call relative",
      Regexp::Expression::Backreference::NumberRelative         => "backreference number relative",
      Regexp::Expression::Backreference::NumberCall             => "backreference number call",
      Regexp::Expression::Backreference::Number                 => "backreference number",
      Regexp::Expression::Backreference::NameRecursionLevel     => "backreference name recursion level",
      Regexp::Expression::Backreference::NameCall               => "backreference name call",
      Regexp::Expression::Backreference::Name                   => "backreference name"
    }.freeze

    CHARACTER_TYPE_LABELS = {
      Regexp::Expression::CharacterType::Any                    => "any character",
      Regexp::Expression::CharacterType::Digit                  => "digit",
      Regexp::Expression::CharacterType::NonDigit               => "non-digit",
      Regexp::Expression::CharacterType::Hex                    => "hex character",
      Regexp::Expression::CharacterType::NonHex                 => "non-hex character",
      Regexp::Expression::CharacterType::Word                   => "word character",
      Regexp::Expression::CharacterType::NonWord                => "non-word character",
      Regexp::Expression::CharacterType::Space                  => "whitespace",
      Regexp::Expression::CharacterType::NonSpace               => "non-whitespace",
      Regexp::Expression::CharacterType::Linebreak              => "line break",
      Regexp::Expression::CharacterType::ExtendedGrapheme       => "extended grapheme"
    }.freeze

    ESCAPE_SEQUENCE_LABELS = {
      Regexp::Expression::EscapeSequence::AsciiEscape           => "ASCII escape",
      Regexp::Expression::EscapeSequence::Backspace             => "backspace",
      Regexp::Expression::EscapeSequence::Bell                  => "bell",
      Regexp::Expression::EscapeSequence::FormFeed              => "form feed",
      Regexp::Expression::EscapeSequence::Newline               => "newline",
      Regexp::Expression::EscapeSequence::Return                => "carriage return",
      Regexp::Expression::EscapeSequence::Tab                   => "tab",
      Regexp::Expression::EscapeSequence::VerticalTab           => "vertical tab",
      Regexp::Expression::EscapeSequence::Octal                 => "octal",
      Regexp::Expression::EscapeSequence::Hex                   => "hex",
      Regexp::Expression::EscapeSequence::Codepoint             => "codepoint",
      Regexp::Expression::EscapeSequence::CodepointList         => "codepoint list"
    }.freeze

    def ast_to_railroad(ast)
      return RailroadDiagrams::Terminal.new("\"#{ast}\"") if ast.is_a?(String)

      case ast
      when Regexp::Expression::Quantifier
        base = ast_to_railroad(ast.base)
        wrap_with_quantifier(base, ast)

      when Regexp::Expression::Root, Regexp::Expression::Sequence
        ast_to_railroad_sequence(ast.expressions)

      when Regexp::Expression::Alternative, Regexp::Expression::Alternation
        RailroadDiagrams::Choice.new(0, *ast.expressions.map { |e| ast_to_railroad(e) })

      when *LABEL_MAP.keys
        group_content = ast_to_railroad_sequence(ast.expressions)
        wrap_with_quantifier(RailroadDiagrams::Group.new(group_content, LABEL_MAP[ast.class]), ast.quantifier)

      when Regexp::Expression::Group::Named
        group_content = ast_to_railroad_sequence(ast.expressions)
        label = ast.name ? "group: #{ast.name}" : "named group"
        wrap_with_quantifier(RailroadDiagrams::Group.new(group_content, label), ast.quantifier)

      when Regexp::Expression::Group::Capture
        group_content = ast_to_railroad_sequence(ast.expressions)
        label = ast.number ? "group ##{ast.number}" : "capture group"
        wrap_with_quantifier(RailroadDiagrams::Group.new(group_content, label), ast.quantifier)

      when Regexp::Expression::Group::Comment
        comment_text = ast.text.gsub(/\A\(\?#|\)\z/, "").strip
        display_text = comment_text.empty? ? "(empty comment)" : comment_text
        RailroadDiagrams::Comment.new(display_text)

      when Regexp::Expression::Group::Options
        if ast.expressions.empty?
          option_flags = ast.text.gsub(/[()?:]/, "")
          label = "options"
          comment = parse_option_flags(option_flags)
          RailroadDiagrams::Group.new(RailroadDiagrams::Comment.new(comment), label)
        else
          group_content = ast_to_railroad_sequence(ast.expressions)
          option_flags = ast.text.gsub(/[()?:]/, "")
          label = "options #{parse_option_flags(option_flags)}"
          wrap_with_quantifier(RailroadDiagrams::Group.new(group_content, label), ast.quantifier)
        end

      when Regexp::Expression::CharacterSet
        label = ast.negative? ? "negated character set" : "character set"

        build_expr = lambda do |e|
          case e
          when Regexp::Expression::CharacterSet::Range
            a, b = e.expressions
            start_char = a.respond_to?(:text) ? a.text : a.to_s
            end_char = b.respond_to?(:text) ? b.text : b.to_s
            RailroadDiagrams::Terminal.new("\"#{start_char}\" - \"#{end_char}\"")

          when Regexp::Expression::CharacterSet::Intersection
            choices = e.expressions.map do |ie|
              inner_items = ie.expressions.map { |sub| build_expr.call(sub) }
              if inner_items.size > 1 && inner_items.all? { |item| item.is_a?(RailroadDiagrams::Terminal) }
                RailroadDiagrams::MultipleChoice.new(0, "any", *inner_items, RailroadDiagrams::Comment.new(label))
              else
                RailroadDiagrams::Sequence.new(*inner_items)
              end
            end
            RailroadDiagrams::MultipleChoice.new(0, "all", *choices, RailroadDiagrams::Comment.new("intersection of character sets"))

          else
            ast_to_railroad(e)
          end
        end

        expressions = ast.expressions.map { |e| build_expr.call(e) }

        mc = RailroadDiagrams::MultipleChoice.new(0, "any", *expressions, RailroadDiagrams::Comment.new(label))
        wrap_with_quantifier(mc, ast.quantifier)

      when *ANCHOR_LABELS.keys
        wrap_with_quantifier(RailroadDiagrams::NonTerminal.new(ANCHOR_LABELS[ast.class]), ast.quantifier)

      when *BACKREFERENCE_CLASSES.keys
        klass = BACKREFERENCE_CLASSES.keys.find { |k| ast.is_a?(k) }
        label = BACKREFERENCE_CLASSES[klass]
        label += ast.respond_to?(:number) ? " \\g<#{ast.number}>" : ""
        label += ast.respond_to?(:token)  ? " \\g<#{ast.token}>"  : ""
        label += ast.respond_to?(:name)   ? " \\k<#{ast.name}>"   : ""
        wrap_with_quantifier(RailroadDiagrams::NonTerminal.new(label.strip), ast.quantifier)

      when *CHARACTER_TYPE_LABELS.keys
        wrap_with_quantifier(RailroadDiagrams::NonTerminal.new(CHARACTER_TYPE_LABELS[ast.class]), ast.quantifier)

      when Regexp::Expression::WhiteSpace
        RailroadDiagrams::Skip.new

      when Regexp::Expression::Comment
        cleaned_comment = ast.text.sub(/^# ?/, "").strip
        RailroadDiagrams::Comment.new(cleaned_comment)

      when Regexp::Expression::Conditional::Expression
        true_branch = ast.branches[0]
        false_branch = ast.branches[1]

        label_true = true_branch ? RailroadDiagrams::Group.new(ast_to_railroad(true_branch), "True") : RailroadDiagrams::Skip.new
        label_false = false_branch ? RailroadDiagrams::Group.new(ast_to_railroad(false_branch), "False") : nil

        choice_expr = label_false ? RailroadDiagrams::Choice.new(0, label_true, label_false) : label_true

        condition_label = case ast.condition.to_s
        when /<([^>]+)>/ then $1
        when /\d+/ then "group ##{$&.to_i}"
        else ast.condition.to_s
        end

        RailroadDiagrams::Group.new(choice_expr, "Condition: #{condition_label}")

      when Regexp::Expression::Keep::Mark, Regexp::Expression::PosixClass, Regexp::Expression::UnicodeProperty::Base
        wrap_with_quantifier(RailroadDiagrams::NonTerminal.new(ast.text), ast.quantifier)

      when Regexp::Expression::Literal
        wrap_with_quantifier(RailroadDiagrams::Terminal.new("\"#{ast.text}\""), ast.quantifier)

      when *ESCAPE_SEQUENCE_LABELS.keys
        wrap_with_quantifier(RailroadDiagrams::NonTerminal.new(ESCAPE_SEQUENCE_LABELS[ast.class]), ast.quantifier)

      # when Regexp::Expression::EscapeSequence::UTF8Hex
      #   wrap_with_quantifier(RailroadDiagrams::NonTerminal.new("UTF-8 hex"), ast.quantifier)

      when Regexp::Expression::EscapeSequence::AbstractMetaControlSequence
        wrap_with_quantifier(RailroadDiagrams::NonTerminal.new("abstract meta control"), ast.quantifier)

      # when Regexp::Expression::EscapeSequence::Control
      #   wrap_with_quantifier(RailroadDiagrams::NonTerminal.new("control character"), ast.quantifier)

      # when Regexp::Expression::EscapeSequence::Meta
      #   wrap_with_quantifier(RailroadDiagrams::NonTerminal.new("meta character"), ast.quantifier)

      # when Regexp::Expression::EscapeSequence::MetaControl
      #   wrap_with_quantifier(RailroadDiagrams::NonTerminal.new("meta control"), ast.quantifier)

      else
        wrap_with_quantifier(RailroadDiagrams::Terminal.new("\"#{ast.text}\""), ast.quantifier)
      end
    end

    def merge_consecutive_literals(expressions)
      merged = []
      buffer = []

      expressions.each do |e|
        if literal_without_quantifier?(e)
          buffer << e
        else
          unless buffer.empty?
            merged << merge_literal_buffer(buffer)
          buffer.clear
          end
          merged << e
        end
      end

      merged << merge_literal_buffer(buffer) unless buffer.empty?
      merged
    end

    def literal_without_quantifier?(e)
      (e.is_a?(Regexp::Expression::Literal) || e.is_a?(Regexp::Expression::EscapeSequence::Literal)) &&
        e.respond_to?(:quantifier) &&
        e.quantifier.nil?
    end

    def merge_literal_buffer(buffer)
      merged_text = buffer.map { |e| e.text.gsub("\\", "") }.join
      merged_text
    end

    def ast_to_railroad_sequence(expressions)
      return RailroadDiagrams::Skip.new if expressions.nil? || expressions.empty?

      sequence_items = merge_consecutive_literals(expressions).map { |e| ast_to_railroad(e) }
      RailroadDiagrams::Sequence.new(*sequence_items)
    end

    def wrap_with_quantifier(base, quant)
      return base unless quant&.respond_to?(:text)

      quant_text = quant.text
      return RailroadDiagrams::Skip.new if ["{0}", "{0,0}", "{,0}"].include?(quant_text)

      matched = quant_text.match(/\A(\*|\+|\?|\{\d*(?:,\d*)?\})([?+]?)\z/)
      return RailroadDiagrams::Group.new(base, "quantifier: #{quant_text}") unless matched

      quant_core = matched[1]
      suffix = matched[2]

      comment_suffix = case suffix
      when "?" then " (lazy)"
      when "+" then " (possessive)"
      else " (greedy)"
      end

      case quant_core
      when "*"
        RailroadDiagrams::ZeroOrMore.new(base, RailroadDiagrams::Comment.new("0 time or more" + comment_suffix))
      when "+"
        RailroadDiagrams::OneOrMore.new(base, RailroadDiagrams::Comment.new("1 time or more" + comment_suffix))
      when "?"
        return base if base.is_a?(RailroadDiagrams::Optional)
        RailroadDiagrams::Optional.new(base)
      when /\A\{(\d+)\}\z/
        n = $1.to_i
        RailroadDiagrams::OneOrMore.new(base, RailroadDiagrams::Comment.new("#{n} time(s)"))
      when /\A\{(\d+),(\d+)\}\z/
        min = $1.to_i
        max = $2.to_i
        if min == max
          RailroadDiagrams::OneOrMore.new(base, RailroadDiagrams::Comment.new("#{min} time(s)"))
        else
          if min == 0
            RailroadDiagrams::ZeroOrMore.new(base, RailroadDiagrams::Comment.new("#{min}-#{max} time(s)"))
          else
            RailroadDiagrams::OneOrMore.new(base, RailroadDiagrams::Comment.new("#{min}-#{max} time(s)"))
          end
        end
      when /\A\{(\d+),\}\z/
        min = $1.to_i
        if min == 0
          RailroadDiagrams::ZeroOrMore.new(base, RailroadDiagrams::Comment.new("0 time or more"))
        else
          RailroadDiagrams::OneOrMore.new(base, RailroadDiagrams::Comment.new("#{min} time(s) or more"))
        end
      when /\A\{,\d+\}\z/
        max = $&.match(/\d+/)[0].to_i rescue 0
        RailroadDiagrams::ZeroOrMore.new(base, RailroadDiagrams::Comment.new("0 - #{max} time(s)"))
      else
        RailroadDiagrams::Group.new(base, "quantifier: #{quant_text}")
      end
    end

    def parse_option_flags(flag_str)
      applied = flag_str[/^[^-]+/] || ""
      negated = flag_str[/-(.+)$/, 1] || ""

      parts = []
      parts << "apply modifiers: #{applied.chars.join(', ')}" unless applied.empty?
      parts << "negate modifiers: #{negated.chars.join(', ')}" unless negated.empty?

      parts.join(" / ")
    end
  end
end
