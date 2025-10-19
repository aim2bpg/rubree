require 'rails_helper'

RSpec.describe RegularExpression::RailroadDiagramGenerator do
  describe '.create_svg_from_regex' do
    context 'when the regex contains quantifiers' do
      it 'generates valid SVG for zero or more quantifier (*)' do
        svg = described_class.create_svg_from_regex('a*')
        expect(svg).to include('<svg')
        expect(svg).to include('0 time or more (greedy)')
      end

      it 'generates valid SVG for one or more quantifier (+)' do
        svg = described_class.create_svg_from_regex('a+')
        expect(svg).to include('<svg')
        expect(svg).to include('1 time or more (greedy)')
      end

      it 'generates valid SVG for complex quantifier with nested groups (a{2,4})+' do
        svg = described_class.create_svg_from_regex('(a{2,4})+')
        expect(svg).to include('<svg')
        expect(svg).to include('1 time or more (greedy)')
      end

      it 'generates valid SVG for possessive quantifier with nested groups (a{2,4})++' do
        svg = described_class.create_svg_from_regex('(a{2,4})++')
        expect(svg).to include('<svg')
        expect(svg).to include('1 time or more (possessive)')
      end

      it 'generates valid SVG for optional quantifier (?)' do
        svg = described_class.create_svg_from_regex('a?')
        expect(svg).to include('<svg')
        expect(svg).to include('&quot;a&quot;')
      end

      it 'generates valid SVG for lazy quantifier (+?)' do
        svg = described_class.create_svg_from_regex('a+?')
        expect(svg).to include('<svg')
        expect(svg).to include('1 time or more (lazy)')
      end

      it 'generates valid SVG for single occurrence quantifier (a{1})' do
        svg = described_class.create_svg_from_regex('a{1}')
        expect(svg).to include('<svg')
        expect(svg).to include('1 time(s)')
      end

      it 'generates valid SVG for exact occurrence quantifier (a{2,2})' do
        svg = described_class.create_svg_from_regex('a{2,2}')
        expect(svg).to include('<svg')
        expect(svg).to include('2 time(s)')
      end

      it 'generates valid SVG for range quantifier (a{0,4})' do
        svg = described_class.create_svg_from_regex('a{0,4}')
        expect(svg).to include('<svg')
        expect(svg).to include('0-4 time(s)')
      end

      it 'generates valid SVG for range quantifier (a{2,4})' do
        svg = described_class.create_svg_from_regex('a{2,4}')
        expect(svg).to include('<svg')
        expect(svg).to include('2-4 time(s)')
      end

      it 'generates valid SVG for zero or more quantifier (a{0,})' do
        svg = described_class.create_svg_from_regex('a{0,}')
        expect(svg).to include('<svg')
        expect(svg).to include('0 time or more')
      end

      it 'generates valid SVG for two or more quantifier (a{2,})' do
        svg = described_class.create_svg_from_regex('a{2,}')
        expect(svg).to include('<svg')
        expect(svg).to include('2 time(s) or more')
      end

      it 'generates valid SVG for quantifier with an upper bound (,4)' do
        svg = described_class.create_svg_from_regex('a{,4}')
        expect(svg).to include('<svg')
        expect(svg).to include('0 - 4 time(s)')
      end

      it 'generates valid SVG for complex range quantifier (a{,0})' do
        svg = described_class.create_svg_from_regex('a{,0}')
        expect(svg).to include('<svg')
        expect(svg).not_to include('</text>')
      end

      it 'handles multiple consecutive quantifiers (a{2,4}b{1,3})' do
        svg = described_class.create_svg_from_regex('a{2,4}b{1,3}')
        expect(svg).to include('<svg')
        expect(svg).to include('2-4 time(s)')
        expect(svg).to include('1-3 time(s)')
      end
    end

    context 'when the regex contains anchors' do
      it 'generates valid SVG for the beginning of line anchor (^)' do
        svg = described_class.create_svg_from_regex('^a')
        expect(svg).to include('<svg')
        expect(svg).to include('beginning of line')
      end

      it 'generates valid SVG for the end of line anchor ($)' do
        svg = described_class.create_svg_from_regex('a$')
        expect(svg).to include('<svg')
        expect(svg).to include('end of line')
      end

      it 'generates valid SVG for the beginning of string anchor (\A)' do
        svg = described_class.create_svg_from_regex('\A')
        expect(svg).to include('<svg')
        expect(svg).to include('beginning of string')
      end

      it 'generates valid SVG for the end of string anchor (\z)' do
        svg = described_class.create_svg_from_regex('\z')
        expect(svg).to include('<svg')
        expect(svg).to include('end of string')
      end

      it 'generates valid SVG for the end of string or before end of line anchor' do
        svg = described_class.create_svg_from_regex('a$|\Z')
        expect(svg).to include('<svg')
        expect(svg).to include('end of string or before end of line')
      end

      it 'generates valid SVG for word boundary anchor (\b)' do
        svg = described_class.create_svg_from_regex('\b')
        expect(svg).to include('<svg')
        expect(svg).to include('word boundary')
      end

      it 'generates valid SVG for non-word boundary anchor (\B)' do
        svg = described_class.create_svg_from_regex('\B')
        expect(svg).to include('<svg')
        expect(svg).to include('non-word boundary')
      end

      it 'generates valid SVG for match start anchor (\G)' do
        svg = described_class.create_svg_from_regex('\G')
        expect(svg).to include('<svg')
        expect(svg).to include('match start')
      end
    end

    context 'when regex contains backreferences' do
      it 'returns valid SVG for a backreference number' do
        svg = described_class.create_svg_from_regex('(abc)\1')
        expect(svg).to include('<svg')
        expect(svg).to include('backreference number')
      end

      it 'returns valid SVG for backreference number recursion level' do
        svg = described_class.create_svg_from_regex('(abc)\k<1-0>')
        expect(svg).to include('<svg')
        expect(svg).to include('backreference number recursion level')
      end

      it 'returns valid SVG for backreference number call' do
        svg = described_class.create_svg_from_regex('(abc)\g<1>')
        expect(svg).to include('<svg')
        expect(svg).to include('backreference number call')
      end

      it 'returns valid SVG for backreference number call relative' do
        svg = described_class.create_svg_from_regex('(abc)\g<-1>')
        expect(svg).to include('<svg')
        expect(svg).to include('backreference number call relative')
      end

      it 'returns valid SVG for backreference number relative' do
        svg = described_class.create_svg_from_regex('(abc)\k<-1>')
        expect(svg).to include('<svg')
        expect(svg).to include('backreference number relative')
      end

      it 'returns valid SVG for backreference name' do
        svg = described_class.create_svg_from_regex('(?<name>abc)\k<name>')
        expect(svg).to include('<svg')
        expect(svg).to include('backreference name')
      end

      it 'returns valid SVG for backreference by name with recursion level' do
        svg = described_class.create_svg_from_regex('(?<name>abc)\k<name-0>')
        expect(svg).to include('<svg')
        expect(svg).to include('backreference name recursion level')
      end

      it 'returns valid SVG for backreference by name call' do
        svg = described_class.create_svg_from_regex('(?<name>abc)\g<name>')
        expect(svg).to include('<svg')
        expect(svg).to include('backreference name call')
      end
    end

    context 'when regex contains character types' do
      it 'returns valid SVG for any character (.)' do
        svg = described_class.create_svg_from_regex('.')
        expect(svg).to include('<svg')
        expect(svg).to include('any character')
      end

      it 'returns valid SVG for a digit (\d)' do
        svg = described_class.create_svg_from_regex('\d')
        expect(svg).to include('<svg')
        expect(svg).to include('digit')
      end

      it 'returns valid SVG for a non-digit (\D)' do
        svg = described_class.create_svg_from_regex('\D')
        expect(svg).to include('<svg')
        expect(svg).to include('non-digit')
      end

      it 'returns valid SVG for a hex character (\h)' do
        svg = described_class.create_svg_from_regex('\h')
        expect(svg).to include('<svg')
        expect(svg).to include('hex character')
      end

      it 'returns valid SVG for a non-hex character (\H)' do
        svg = described_class.create_svg_from_regex('\H')
        expect(svg).to include('<svg')
        expect(svg).to include('non-hex character')
      end

      it 'returns valid SVG for a word character (\w)' do
        svg = described_class.create_svg_from_regex('\w')
        expect(svg).to include('<svg')
        expect(svg).to include('word character')
      end

      it 'returns valid SVG for a non-word character (\W)' do
        svg = described_class.create_svg_from_regex('\W')
        expect(svg).to include('<svg')
        expect(svg).to include('non-word character')
      end

      it 'returns valid SVG for whitespace (\s)' do
        svg = described_class.create_svg_from_regex('\s')
        expect(svg).to include('<svg')
        expect(svg).to include('whitespace')
      end

      it 'returns valid SVG for non-whitespace (\S)' do
        svg = described_class.create_svg_from_regex('\S')
        expect(svg).to include('<svg')
        expect(svg).to include('non-whitespace')
      end

      it 'returns valid SVG for a line break (\R)' do
        svg = described_class.create_svg_from_regex('\R')
        expect(svg).to include('<svg')
        expect(svg).to include('line break')
      end

      it 'returns valid SVG for an extended grapheme (\X)' do
        svg = described_class.create_svg_from_regex('\X')
        expect(svg).to include('<svg')
        expect(svg).to include('extended grapheme')
      end

      it 'returns valid SVG for a space character' do
        svg = described_class.create_svg_from_regex(' ')
        expect(svg).to include('<svg')
        expect(svg).to include('&quot; &quot;')
      end

      it 'returns valid SVG for a comment' do
        svg = described_class.create_svg_from_regex('(?x)a # comment')
        expect(svg).to include('<svg')
        expect(svg).to include('class="comment"')
      end

      it 'returns valid SVG for a conditional expression (1)' do
        svg = described_class.create_svg_from_regex('(?<A>a)(?(<A>)T|)')
        expect(svg).to include('<svg')
        expect(svg).to include('Condition: A')
      end

      it 'returns valid SVG for a conditional expression (2)' do
        svg = described_class.create_svg_from_regex('(a)(?(001)T)')
        expect(svg).to include('<svg')
        expect(svg).to include('Condition: group #1')
      end

      it 'returns valid SVG for an atomic group (?>)' do
        svg = described_class.create_svg_from_regex('(?>a)')
        expect(svg).to include('<svg')
        expect(svg).to include('atomic group')
      end

      it 'returns valid SVG for an absence group (?~)' do
        svg = described_class.create_svg_from_regex('(?~a)')
        expect(svg).to include('<svg')
        expect(svg).to include('absence group')
      end

      it 'returns valid SVG for a named group (?<groupname>)' do
        svg = described_class.create_svg_from_regex('(?<groupname>a)')
        expect(svg).to include('<svg')
        expect(svg).to include('group: groupname')
      end

      it 'returns valid SVG for an options group (?ix)' do
        svg = described_class.create_svg_from_regex('(?ix)a')
        expect(svg).to include('<svg')
        expect(svg).to include('options')
        expect(svg).to include('i, x')
      end

      it 'returns valid SVG for a non-capturing group (?:)' do
        svg = described_class.create_svg_from_regex('(?:a)')
        expect(svg).to include('<svg')
        expect(svg).to include('non-capturing group')
      end

      it 'returns valid SVG for a negated character set ([^a])' do
        svg = described_class.create_svg_from_regex('[^a]')
        expect(svg).to include('<svg')
        expect(svg).to include('negated character set')
      end

      it 'returns valid SVG for a character set ([a-z])' do
        svg = described_class.create_svg_from_regex('[a-z]')
        expect(svg).to include('<svg')
        expect(svg).to include('character set')
      end

      it 'returns valid SVG for a character set with range ([a-d])' do
        svg = described_class.create_svg_from_regex('[a-d]')
        expect(svg).to include('<svg')
        expect(svg).to include('&quot;a&quot; - &quot;d&quot;')
      end

      it 'returns valid SVG for a character set intersection ([a-d&&aeiou])' do
        svg = described_class.create_svg_from_regex('[a-d&&aeiou]')
        expect(svg).to include('<svg')
        expect(svg).to include('intersection of character sets')
      end

      it 'returns valid SVG for a conditional expression with group (a$|\Z)' do
        svg = described_class.create_svg_from_regex('a$|\Z')
        expect(svg).to include('<svg')
        expect(svg).to include('end of string or before end of line')
      end

      it 'returns valid SVG for an optional quantifier with group ((a)?)' do
        svg = described_class.create_svg_from_regex('(a)?')
        expect(svg).to include('<svg')
        expect(svg).to include('&quot;a&quot;')
      end

      it 'handles invalid regex gracefully' do
        expect { described_class.create_svg_from_regex('[a') }.to raise_error(RegexpError)
      end

      it 'returns valid SVG for a conditional group (a(b|c))' do
        svg = described_class.create_svg_from_regex('a(b|c)')
        expect(svg).to include('<svg')
        expect(svg).to include('&quot;b&quot;')
      end

      it 'returns valid SVG for a keep mark (ab\Kcd)' do
        svg = described_class.create_svg_from_regex('ab\Kcd')
        expect(svg).to include('<svg')
        expect(svg).to include('&quot;cd&quot;')
      end

      it 'returns valid SVG for a single literal (\g)' do
        svg = described_class.create_svg_from_regex('\g')
        expect(svg).to include('<svg')
        expect(svg).to include('&quot;g&quot;')
      end

      it 'returns valid SVG for a multi literal (c\gt)' do
        svg = described_class.create_svg_from_regex('c\gt')
        expect(svg).to include('<svg')
        expect(svg).to include('&quot;cgt&quot;')
      end

      it 'returns valid SVG for POSIX class ([[:digit:]])' do
        svg = described_class.create_svg_from_regex('[[:digit:]]')
        expect(svg).to include('<svg')
        expect(svg).to include('[:digit:]')
      end

      it 'returns valid SVG for Unicode property base ([\p{L}])' do
        svg = described_class.create_svg_from_regex('[\p{L}]')
        expect(svg).to include('<svg')
        expect(svg).to include('\p{L}')
      end

      it 'returns valid SVG for ASCII escape sequence (a\ec)' do
        svg = described_class.create_svg_from_regex('a\ec')
        expect(svg).to include('<svg')
        expect(svg).to include('ASCII escape')
      end

      it 'returns valid SVG for backspace escape sequence ([\b])' do
        svg = described_class.create_svg_from_regex('[\b]')
        expect(svg).to include('<svg')
        expect(svg).to include('backspace')
      end

      it 'returns valid SVG for bell escape sequence (\a)' do
        svg = described_class.create_svg_from_regex('\a')
        expect(svg).to include('<svg')
        expect(svg).to include('bell')
      end

      it 'returns valid SVG for form feed escape sequence (\f)' do
        svg = described_class.create_svg_from_regex('\f')
        expect(svg).to include('<svg')
        expect(svg).to include('form feed')
      end

      it 'returns valid SVG for newline escape sequence (\n)' do
        svg = described_class.create_svg_from_regex('\n')
        expect(svg).to include('<svg')
        expect(svg).to include('newline')
      end

      it 'returns valid SVG for carriage return escape sequence (\r)' do
        svg = described_class.create_svg_from_regex('\r')
        expect(svg).to include('<svg')
        expect(svg).to include('carriage return')
      end

      it 'returns valid SVG for tab escape sequence (\t)' do
        svg = described_class.create_svg_from_regex('\t')
        expect(svg).to include('<svg')
        expect(svg).to include('tab')
      end

      it 'returns valid SVG for vertical tab escape sequence (\v)' do
        svg = described_class.create_svg_from_regex('\v')
        expect(svg).to include('<svg')
        expect(svg).to include('vertical tab')
      end

      it 'returns valid SVG for literal escape sequence (\")' do
        svg = described_class.create_svg_from_regex('\\"')
        expect(svg).to include('<svg')
        expect(svg).to include('&quot;&quot;&quot;')
      end

      it 'returns valid SVG for octal escape sequence (\0)' do
        svg = described_class.create_svg_from_regex('\0')
        expect(svg).to include('<svg')
        expect(svg).to include('octal')
      end

      it 'returns valid SVG for hex escape sequence (\x41)' do
        svg = described_class.create_svg_from_regex('\x41')
        expect(svg).to include('<svg')
        expect(svg).to include('hex')
      end

      it 'returns valid SVG for codepoint escape sequence (\u0640)' do
        svg = described_class.create_svg_from_regex('\u0640')
        expect(svg).to include('<svg')
        expect(svg).to include('codepoint</text>')
      end

      it 'returns valid SVG for codepoint list escape sequence (\u{640 0641})' do
        svg = described_class.create_svg_from_regex('\u{640 0641}')
        expect(svg).to include('<svg')
        expect(svg).to include('codepoint list')
      end

      it 'returns valid SVG for UTF-8 hex escape sequence (\xE2\x82\xAC)' do
        svg = described_class.create_svg_from_regex('\xE2\x82\xAC')
        expect(svg).to include('<svg')
        expect(svg).to include('hex')
      end

      it 'returns valid SVG for abstract meta control escape sequence (\C-C)' do
        svg = described_class.create_svg_from_regex('\C-C')
        expect(svg).to include('<svg')
        expect(svg).to include('abstract meta control')
      end

      ## RegexpError: too short escaped multibyte character: /\M-c/
      # it 'returns valid SVG for control character escape sequence' do
      #   svg = described_class.create_svg_from_regex('\M-c')
      #   expect(svg).to include('<svg')
      #   expect(svg).to include('control character')
      # end

      ## RegexpError: invalid multibyte escape: /\M-\C-C/
      # it 'returns valid SVG for meta character escape sequence' do
      #   svg = described_class.create_svg_from_regex('\M-\C-C')
      #   expect(svg).to include('<svg')
      #   expect(svg).to include('meta character')
      # end

      ## RegexpError: invalid multibyte escape: /\M-\cC/
      # it 'returns valid SVG for meta control escape sequence' do
      #   svg = described_class.create_svg_from_regex('\M-\cC')
      #   expect(svg).to include('<svg')
      #   expect(svg).to include('meta control')
      # end

      ## RegexpError: invalid multibyte escape: /\C-\M-C/
      # it 'returns valid SVG for unknown escape sequence' do
      #   svg = described_class.create_svg_from_regex('\0')
      #   expect(svg).to include('<svg')
      #   expect(svg).to include('\C-\M-C')
      # end
    end

    context 'when regex contains special characters and options' do
      it 'returns valid SVG for dot (.)' do
        svg = described_class.create_svg_from_regex('a.b')
        expect(svg).to include('<svg')
        expect(svg).to include('any character')
      end

      it 'returns SVG with options applied' do
        svg = described_class.create_svg_from_regex('(?ix:a)')
        expect(svg).to include('<svg')
        expect(svg).to include('options apply modifiers: i, x')
      end

      ## RegexpError: undefined group option: /(?g:a)/
      # it 'returns SVG with global flag' do
      #   svg = described_class.create_svg_from_regex('(?g:a)')
      #   expect(svg).to include('<svg')
      #   expect(svg).to include('options: g')
      # end
    end

    context 'when regex contains assertions' do
      it 'returns valid SVG for positive lookahead' do
        svg = described_class.create_svg_from_regex('a(?=b)')
        expect(svg).to include('<svg')
        expect(svg).to include('positive lookahead')
      end

      it 'returns valid SVG for negative lookahead' do
        svg = described_class.create_svg_from_regex('a(?!b)')
        expect(svg).to include('<svg')
        expect(svg).to include('negative lookahead')
      end

      it 'returns valid SVG for positive lookbehind' do
        svg = described_class.create_svg_from_regex('(?<=a)b')
        expect(svg).to include('<svg')
        expect(svg).to include('positive lookbehind')
      end

      it 'returns valid SVG for negative lookbehind' do
        svg = described_class.create_svg_from_regex('(?<!a)b')
        expect(svg).to include('<svg')
        expect(svg).to include('negative lookbehind')
      end
    end

    context 'when regex contains complex patterns' do
      it 'returns valid SVG for complex alternation with nested groups' do
        svg = described_class.create_svg_from_regex('(a|b(c|d)+)+')
        expect(svg).to include('<svg')
        expect(svg).to include('&quot;d&quot;')
      end

      it 'returns valid SVG for deeply nested alternation' do
        svg = described_class.create_svg_from_regex('a(b(c|d(e|f)g|h)i|j)')
        expect(svg).to include('<svg')
        expect(svg).to include('&quot;j&quot;')
      end
    end

    context 'when regex contains whitespace and comments' do
      it 'returns SVG with whitespace handling' do
        svg = described_class.create_svg_from_regex('a\s+')
        expect(svg).to include('<svg')
        expect(svg).to include('whitespace')
      end

      it 'returns SVG with comments' do
        svg = described_class.create_svg_from_regex('a(?#comment)b')
        expect(svg).to include('<svg')
        expect(svg).to include('comment')
      end

      it 'handles multiple whitespace' do
        svg = described_class.create_svg_from_regex('a\s*\sb')
        expect(svg).to include('<svg')
        expect(svg).to include('whitespace')
      end

      it 'handles multiple comments' do
        svg = described_class.create_svg_from_regex('a(?#first)(?#second)b')
        expect(svg).to include('<svg')
        expect(svg).to include('&quot;a&quot;')
        expect(svg).to include('&quot;b&quot;')
      end
    end

    context 'when regex contains empty or invalid regex string' do
      it 'returns a valid SVG string or empty string for empty regex' do
        svg = described_class.create_svg_from_regex('')
        expect(svg).to be_a(String)
      end

      it 'raises error for malformed regex' do
        expect { described_class.create_svg_from_regex('[') }.to raise_error(RegexpError)
      end
    end
  end
end
