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

    # Human-readable labels for control characters rendered as standalone NonTerminal nodes.
    # Matches the "name (0xNN)" convention used by regexper.com.
    CONTROL_CHAR_NAMES = {
      "\0"  => "null (0x00)",
      "\t"  => "tab (0x09)",
      "\n"  => "line feed (0x0A)",
      "\v"  => "vertical tab (0x0B)",
      "\f"  => "form feed (0x0C)",
      "\r"  => "carriage return (0x0D)"
    }.freeze

    # Short escape notation used when a control character appears embedded inside a
    # longer printable literal string (e.g. the merged "a\nb" terminal label).
    CONTROL_CHAR_ESCAPES = {
      "\n" => '\n',
      "\t" => '\t',
      "\r" => '\r',
      "\f" => '\f',
      "\v" => '\v',
      "\0" => '\0'
    }.freeze

    ESCAPE_SEQUENCE_LABELS = {
      Regexp::Expression::EscapeSequence::AsciiEscape           => "escape (0x1B)",
      Regexp::Expression::EscapeSequence::Backspace             => "backspace (0x08)",
      Regexp::Expression::EscapeSequence::Bell                  => "bell (0x07)",
      Regexp::Expression::EscapeSequence::FormFeed              => "form feed (0x0C)",
      Regexp::Expression::EscapeSequence::Newline               => "line feed (0x0A)",
      Regexp::Expression::EscapeSequence::Return                => "carriage return (0x0D)",
      Regexp::Expression::EscapeSequence::Tab                   => "tab (0x09)",
      Regexp::Expression::EscapeSequence::VerticalTab           => "vertical tab (0x0B)",
      Regexp::Expression::EscapeSequence::Octal                 => "octal",
      Regexp::Expression::EscapeSequence::Hex                   => "hex",
      Regexp::Expression::EscapeSequence::Codepoint             => "codepoint",
      Regexp::Expression::EscapeSequence::CodepointList         => "codepoint list",
      Regexp::Expression::EscapeSequence::Control               => "control character"
    }.freeze

    def escape_literal_text(text)
      text.gsub(/[\x00-\x1f\x7f]/) do |char|
        CONTROL_CHAR_ESCAPES[char] || "\\x#{char.ord.to_s(16).upcase.rjust(2, '0')}"
      end
    end

    def literal_with_controls_to_railroad(text)
      nodes = text.scan(/[\x00-\x1f\x7f]|[^\x00-\x1f\x7f]+/).flat_map do |seg|
        if seg.length == 1 && seg.match?(/[\x00-\x1f\x7f]/)
          label = CONTROL_CHAR_NAMES[seg] || "\\x#{seg.ord.to_s(16).upcase.rjust(2, '0')}"
          [RailroadDiagrams::NonTerminal.new(label)]
        else
          [RailroadDiagrams::Terminal.new("\"#{escape_literal_text(seg)}\"")]
        end
      end
      nodes.size == 1 ? nodes.first : RailroadDiagrams::Sequence.new(*nodes)
    end

    def ast_to_railroad(ast)
      return RailroadDiagrams::Terminal.new("\"#{escape_literal_text(ast)}\"") if ast.is_a?(String)

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
        safe_name = sanitize_group_name(ast.name)
        label = safe_name ? "group: #{safe_name}" : "unknown group"
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
            e.case_insensitive? ? ci_range_to_railroad(start_char, end_char) : RailroadDiagrams::Terminal.new("\"#{start_char}\" - \"#{end_char}\"")

          when Regexp::Expression::CharacterSet::Intersection
            choices = e.expressions.map do |ie|
              inner_items = ie.expressions.map { |sub| build_expr.call(sub) }
              case inner_items.size
              when 0 then RailroadDiagrams::Skip.new
              when 1 then inner_items.first
              else RailroadDiagrams::Group.new(RailroadDiagrams::Choice.new(0, *inner_items), label)
              end
            end
            RailroadDiagrams::MultipleChoice.new(0, "all", *choices, RailroadDiagrams::Comment.new("intersection of character sets"))

          else
            ast_to_railroad(e)
          end
        end

        expressions = ast.expressions.map { |e| build_expr.call(e) }

        choice = case expressions.size
        when 0 then RailroadDiagrams::Skip.new
        when 1 then expressions.first
        else RailroadDiagrams::Choice.new(0, *expressions)
        end
        wrap_with_quantifier(RailroadDiagrams::Group.new(choice, label), ast.quantifier)

      when *ANCHOR_LABELS.keys
        wrap_with_quantifier(RailroadDiagrams::NonTerminal.new(ANCHOR_LABELS[ast.class]), ast.quantifier)

      when *BACKREFERENCE_CLASSES.keys
        klass = BACKREFERENCE_CLASSES.keys.find { |k| ast.is_a?(k) }
        label = "#{BACKREFERENCE_CLASSES[klass]} #{ast.text}".strip
        wrap_with_quantifier(RailroadDiagrams::NonTerminal.new(label), ast.quantifier)

      when *CHARACTER_TYPE_LABELS.keys
        label = if ast.is_a?(Regexp::Expression::CharacterType::Any) && ast.multiline?
          "any character (including newline)"
        else
          CHARACTER_TYPE_LABELS[ast.class]
        end
        wrap_with_quantifier(RailroadDiagrams::NonTerminal.new(label), ast.quantifier)

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
        if ast.text.match?(/[\x00-\x1f\x7f]/)
          wrap_with_quantifier(literal_with_controls_to_railroad(ast.text), ast.quantifier)
        elsif ast.case_insensitive?
          wrap_with_quantifier(ci_literal_to_railroad(ast.text), ast.quantifier)
        else
          wrap_with_quantifier(RailroadDiagrams::Terminal.new("\"#{escape_literal_text(ast.text)}\""), ast.quantifier)
        end

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
        wrap_with_quantifier(RailroadDiagrams::Terminal.new("\"#{escape_literal_text(ast.text)}\""), ast.quantifier)
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
        e.quantifier.nil? &&
        !e.case_insensitive? &&
        !e.text.match?(/[\x00-\x1f\x7f]/)
    end

    # Builds a railroad node for a case-insensitive literal string.
    # Handles three cases:
    #   - 1:1 fold chars (e.g. "a"): Choice of single-char equivalents
    #   - multi-char fold chars (e.g. "ß" → "ss"): recursive expansion + compact single-char alt
    #   - adjacent char pairs/triples whose combined fold has a single-char alternative
    #     (e.g. "St" → ﬆ/ﬅ): grouped as Choice(normal-sequence, single-char-alt)
    def ci_literal_to_railroad(text)
      chars = text.chars
      return ci_char_to_node(chars.first) if chars.size == 1

      nodes = build_ci_sequence_nodes(chars)
      nodes.size == 1 ? nodes.first : RailroadDiagrams::Sequence.new(*nodes)
    end

    # Processes a char array into railroad nodes, grouping adjacent chars into
    # Choice nodes when a single input character can match the whole span.
    # e.g. ["S","t"] → Choice(Sequence(Choice(S,s,ſ),Choice(T,t)), Choice(ﬆ,ﬅ))
    def build_ci_sequence_nodes(chars)
      result = []
      i = 0

      while i < chars.size
        char = chars[i]
        char_fold = char.downcase(:fold)

        if char_fold.length > 1
          result << ci_char_to_node(char)
          i += 1
          next
        end

        span_found = false
        max_span = [3, chars.size - i].min

        (2..max_span).each do |span_len|
          break if span_found
          span = chars[i, span_len]
          next if span[1..].any? { |c| c.downcase(:fold).length > 1 }

          span_fold = span.map { |c| c.downcase(:fold) }.join
          alts = RegularExpression::CaseFoldTable.single_char_variants_for_fold(span_fold)
          next if alts.empty?

          sub_nodes = span.map { |c| ci_char_to_node(c) }
          normal_path = RailroadDiagrams::Sequence.new(*sub_nodes)
          result << RailroadDiagrams::Choice.new(0, normal_path, build_choice_terminal(alts))
          i += span_len
          span_found = true
        end

        unless span_found
          result << ci_char_to_node(char)
          i += 1
        end
      end

      result
    end

    # Returns the railroad node for a single CI literal character.
    # If the character folds to multiple chars (e.g. ß → "ss"), delegates to
    # ci_literal_to_railroad on the fold key, which handles multi-char expansion
    # and single-char alternatives (ß, ẞ) via build_ci_sequence_nodes.
    def ci_char_to_node(char)
      return literal_with_controls_to_railroad(char) if char.match?(/[\x00-\x1f\x7f]/)

      fold_key = char.downcase(:fold)
      if fold_key.length > 1
        ci_literal_to_railroad(fold_key)
      else
        variants = RegularExpression::CaseFoldTable.single_char_variants(char)
        variants.size <= 1 ? RailroadDiagrams::Terminal.new("\"#{char}\"") : build_choice_terminal(variants)
      end
    end

    def build_choice_terminal(chars)
      terminals = chars.map { |c| RailroadDiagrams::Terminal.new("\"#{c}\"") }
      terminals.size == 1 ? terminals.first : RailroadDiagrams::Choice.new(0, *terminals)
    end

    # Returns a railroad node for a character range under case-insensitive matching.
    # When both endpoints have single-char CI alternatives, wraps the original range
    # in a Choice with the complementary-case range (e.g. "a"-"z" and "A"-"Z").
    def ci_range_to_railroad(start_char, end_char)
      original = RailroadDiagrams::Terminal.new("\"#{start_char}\" - \"#{end_char}\"")

      start_others = RegularExpression::CaseFoldTable.single_char_variants(start_char).reject { |c| c == start_char }
      end_others   = RegularExpression::CaseFoldTable.single_char_variants(end_char).reject { |c| c == end_char }

      return original if start_others.empty? || end_others.empty?

      alt = RailroadDiagrams::Terminal.new("\"#{start_others.first}\" - \"#{end_others.first}\"")
      RailroadDiagrams::Choice.new(0, original, alt)
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

    # Returns a sanitized group name if it's safe to display/use in labels and
    # backreferences. Unsafe names (e.g. containing non-word characters or
    # invalid byte sequences) will return nil.
    def sanitize_group_name(name)
      return nil if name.nil?

      # Strip invalid/undefined byte sequences (replace with empty string so we
      # can detect that something was removed rather than masking with "?").
      safe = name.to_s.encode("UTF-8", invalid: :replace, undef: :replace, replace: "")
      return nil if safe.empty?

      # Mirror Ruby's named-capture identifier rules: must start with a Unicode
      # letter or underscore, followed by Unicode letters, digits, or underscores.
      # This covers ASCII names as well as non-ASCII names (e.g. Japanese).
      return safe if safe.match?(/\A[\p{L}_][\p{L}\p{N}_]*\z/u)

      nil
    end
  end
end
