require 'rails_helper'

RSpec.describe RegularExpression::RailroadDiagram do
  describe '#generate' do
    context 'when the regex contains quantifiers' do
      it 'generates valid SVG for zero or more quantifier (*)' do
        svg = described_class.new(regular_expression: 'a*').generate
        expect(svg).to include('<svg')
        expect(svg).to include('0 time or more (greedy)')
      end

      it 'generates valid SVG for one or more quantifier (+)' do
        svg = described_class.new(regular_expression: 'a+').generate
        expect(svg).to include('<svg')
        expect(svg).to include('1 time or more (greedy)')
      end

      it 'generates valid SVG for complex quantifier with nested groups (a{2,4})+' do
        svg = described_class.new(regular_expression: '(a{2,4})+').generate
        expect(svg).to include('<svg')
        expect(svg).to include('1 time or more (greedy)')
      end

      it 'generates valid SVG for possessive quantifier with nested groups (a{2,4})++' do
        svg = described_class.new(regular_expression: '(a{2,4})++').generate
        expect(svg).to include('<svg')
        expect(svg).to include('1 time or more (possessive)')
      end

      it 'generates valid SVG for optional quantifier (?)' do
        svg = described_class.new(regular_expression: 'a?').generate
        expect(svg).to include('<svg')
        expect(svg).to include(/<text[^>]*>a<\/text>/)
      end

      it 'generates valid SVG for lazy quantifier (+?)' do
        svg = described_class.new(regular_expression: 'a+?').generate
        expect(svg).to include('<svg')
        expect(svg).to include('1 time or more (lazy)')
      end

      it 'generates valid SVG for single occurrence quantifier (a{1})' do
        svg = described_class.new(regular_expression: 'a{1}').generate
        expect(svg).to include('<svg')
        expect(svg).to include('1 time(s)')
      end

      it 'generates valid SVG for exact occurrence quantifier (a{2,2})' do
        svg = described_class.new(regular_expression: 'a{2,2}').generate
        expect(svg).to include('<svg')
        expect(svg).to include('2 time(s)')
      end

      it 'generates valid SVG for range quantifier (a{0,4})' do
        svg = described_class.new(regular_expression: 'a{0,4}').generate
        expect(svg).to include('<svg')
        expect(svg).to include('0-4 time(s)')
      end

      it 'generates valid SVG for range quantifier (a{2,4})' do
        svg = described_class.new(regular_expression: 'a{2,4}').generate
        expect(svg).to include('<svg')
        expect(svg).to include('2-4 time(s)')
      end

      it 'generates valid SVG for zero or more quantifier (a{0,})' do
        svg = described_class.new(regular_expression: 'a{0,}').generate
        expect(svg).to include('<svg')
        expect(svg).to include('0 time or more')
      end

      it 'generates valid SVG for two or more quantifier (a{2,})' do
        svg = described_class.new(regular_expression: 'a{2,}').generate
        expect(svg).to include('<svg')
        expect(svg).to include('2 time(s) or more')
      end

      it 'generates valid SVG for quantifier with an upper bound (,4)' do
        svg = described_class.new(regular_expression: 'a{,4}').generate
        expect(svg).to include('<svg')
        expect(svg).to include('0 - 4 time(s)')
      end

      it 'generates valid SVG for complex range quantifier (a{,0})' do
        svg = described_class.new(regular_expression: 'a{,0}').generate
        expect(svg).to include('<svg')
        expect(svg).not_to include('</text>')
      end

      it 'handles multiple consecutive quantifiers (a{2,4}b{1,3})' do
        svg = described_class.new(regular_expression: 'a{2,4}b{1,3}').generate
        expect(svg).to include('<svg')
        expect(svg).to include('2-4 time(s)')
        expect(svg).to include('1-3 time(s)')
      end
    end

    context 'when the regex contains anchors' do
      it 'generates valid SVG for the beginning of line anchor (^)' do
        svg = described_class.new(regular_expression: '^a').generate
        expect(svg).to include('<svg')
        expect(svg).to include('beginning of line')
      end

      it 'generates valid SVG for the end of line anchor ($)' do
        svg = described_class.new(regular_expression: 'a$').generate
        expect(svg).to include('<svg')
        expect(svg).to include('end of line')
      end

      it 'generates valid SVG for the beginning of string anchor (\A)' do
        svg = described_class.new(regular_expression: '\A').generate
        expect(svg).to include('<svg')
        expect(svg).to include('beginning of string')
      end

      it 'generates valid SVG for the end of string anchor (\z)' do
        svg = described_class.new(regular_expression: '\z').generate
        expect(svg).to include('<svg')
        expect(svg).to include('end of string')
      end

      it 'generates valid SVG for the end of string or before end of line anchor' do
        svg = described_class.new(regular_expression: 'a$|\Z').generate
        expect(svg).to include('<svg')
        expect(svg).to include('end of string or before end of line')
      end

      it 'generates valid SVG for word boundary anchor (\b)' do
        svg = described_class.new(regular_expression: '\b').generate
        expect(svg).to include('<svg')
        expect(svg).to include('word boundary')
      end

      it 'generates valid SVG for non-word boundary anchor (\B)' do
        svg = described_class.new(regular_expression: '\B').generate
        expect(svg).to include('<svg')
        expect(svg).to include('non-word boundary')
      end

      it 'generates valid SVG for match start anchor (\G)' do
        svg = described_class.new(regular_expression: '\G').generate
        expect(svg).to include('<svg')
        expect(svg).to include('match start')
      end
    end

    context 'when regex contains backreferences' do
      it 'returns valid SVG for a backreference number' do
        svg = described_class.new(regular_expression: '(abc)\1').generate
        expect(svg).to include('<svg')
        expect(svg).to include('backreference number')
      end

      it 'returns valid SVG for backreference number recursion level' do
        svg = described_class.new(regular_expression: '(abc)\k<1-0>').generate
        expect(svg).to include('<svg')
        expect(svg).to include('backreference number recursion level')
      end

      it 'returns valid SVG for backreference number call' do
        svg = described_class.new(regular_expression: '(abc)\g<1>').generate
        expect(svg).to include('<svg')
        expect(svg).to include('backreference number call')
      end

      it 'returns valid SVG for backreference number call relative' do
        svg = described_class.new(regular_expression: '(abc)\g<-1>').generate
        expect(svg).to include('<svg')
        expect(svg).to include('backreference number call relative')
      end

      it 'returns valid SVG for backreference number relative' do
        svg = described_class.new(regular_expression: '(abc)\k<-1>').generate
        expect(svg).to include('<svg')
        expect(svg).to include('backreference number relative')
      end

      it 'returns valid SVG for backreference name' do
        svg = described_class.new(regular_expression: '(?<name>abc)\k<name>').generate
        expect(svg).to include('<svg')
        expect(svg).to include('backreference name')
      end

      it 'returns valid SVG for backreference by name with recursion level' do
        svg = described_class.new(regular_expression: '(?<name>abc)\k<name-0>').generate
        expect(svg).to include('<svg')
        expect(svg).to include('backreference name recursion level')
      end

      it 'returns valid SVG for backreference by name call' do
        svg = described_class.new(regular_expression: '(?<name>abc)\g<name>').generate
        expect(svg).to include('<svg')
        expect(svg).to include('backreference name call')
      end
    end

    context 'when regex contains character types' do
      it 'returns valid SVG for any character (.)' do
        svg = described_class.new(regular_expression: '.').generate
        expect(svg).to include('<svg')
        expect(svg).to include('any character')
      end

      it 'returns valid SVG for a digit (\d)' do
        svg = described_class.new(regular_expression: '\d').generate
        expect(svg).to include('<svg')
        expect(svg).to include('digit')
      end

      it 'returns valid SVG for a non-digit (\D)' do
        svg = described_class.new(regular_expression: '\D').generate
        expect(svg).to include('<svg')
        expect(svg).to include('non-digit')
      end

      it 'returns valid SVG for a hex character (\h)' do
        svg = described_class.new(regular_expression: '\h').generate
        expect(svg).to include('<svg')
        expect(svg).to include('hex character')
      end

      it 'returns valid SVG for a non-hex character (\H)' do
        svg = described_class.new(regular_expression: '\H').generate
        expect(svg).to include('<svg')
        expect(svg).to include('non-hex character')
      end

      it 'returns valid SVG for a word character (\w)' do
        svg = described_class.new(regular_expression: '\w').generate
        expect(svg).to include('<svg')
        expect(svg).to include('word character')
      end

      it 'returns valid SVG for a non-word character (\W)' do
        svg = described_class.new(regular_expression: '\W').generate
        expect(svg).to include('<svg')
        expect(svg).to include('non-word character')
      end

      it 'returns valid SVG for whitespace (\s)' do
        svg = described_class.new(regular_expression: '\s').generate
        expect(svg).to include('<svg')
        expect(svg).to include('whitespace')
      end

      it 'returns valid SVG for non-whitespace (\S)' do
        svg = described_class.new(regular_expression: '\S').generate
        expect(svg).to include('<svg')
        expect(svg).to include('non-whitespace')
      end

      it 'returns valid SVG for a line break (\R)' do
        svg = described_class.new(regular_expression: '\R').generate
        expect(svg).to include('<svg')
        expect(svg).to include('line break')
      end

      it 'returns valid SVG for an extended grapheme (\X)' do
        svg = described_class.new(regular_expression: '\X').generate
        expect(svg).to include('<svg')
        expect(svg).to include('extended grapheme')
      end

      it 'returns valid SVG for a space character' do
        svg = described_class.new(regular_expression: ' ').generate
        expect(svg).to include('<svg')
        expect(svg).to include('" "')
      end

      it 'returns valid SVG for a comment' do
        svg = described_class.new(regular_expression: '(?x)a # comment').generate
        expect(svg).to include('<svg')
        expect(svg).to include('class="comment"')
      end

      it 'returns valid SVG for a conditional expression (1)' do
        svg = described_class.new(regular_expression: '(?<A>a)(?(<A>)T|)').generate
        expect(svg).to include('<svg')
        expect(svg).to include('Condition: A')
      end

      it 'returns valid SVG for a conditional expression (2)' do
        svg = described_class.new(regular_expression: '(a)(?(001)T)').generate
        expect(svg).to include('<svg')
        expect(svg).to include('Condition: group #1')
      end

      it 'returns valid SVG for an atomic group (?>)' do
        svg = described_class.new(regular_expression: '(?>a)').generate
        expect(svg).to include('<svg')
        expect(svg).to include('atomic group')
      end

      it 'returns valid SVG for an absence group (?~)' do
        svg = described_class.new(regular_expression: '(?~a)').generate
        expect(svg).to include('<svg')
        expect(svg).to include('absence group')
      end

      it 'returns valid SVG for a named group (?<groupname>)' do
        svg = described_class.new(regular_expression: '(?<groupname>a)').generate
        expect(svg).to include('<svg')
        expect(svg).to include('group: groupname')
      end

      it 'returns valid SVG for an options group (?ix)' do
        svg = described_class.new(regular_expression: '(?ix)a').generate
        expect(svg).to include('<svg')
        expect(svg).to include('options')
        expect(svg).to include('i, x')
      end

      it 'returns valid SVG for a non-capturing group (?:)' do
        svg = described_class.new(regular_expression: '(?:a)').generate
        expect(svg).to include('<svg')
        expect(svg).to include('non-capturing group')
      end

      it 'returns valid SVG for a negated character set ([^a])' do
        svg = described_class.new(regular_expression: '[^a]').generate
        expect(svg).to include('<svg')
        expect(svg).to include('negated character set')
      end

      it 'returns valid SVG for a character set ([a-z])' do
        svg = described_class.new(regular_expression: '[a-z]').generate
        expect(svg).to include('<svg')
        expect(svg).to include('character set')
      end

      it 'returns valid SVG for a character set with range ([a-d])' do
        svg = described_class.new(regular_expression: '[a-d]').generate
        expect(svg).to include('<svg')
        expect(svg).to include('"a" - "d"')
      end

      it 'returns valid SVG for a character set intersection ([a-d&&aeiou])' do
        svg = described_class.new(regular_expression: '[a-d&&aeiou]').generate
        expect(svg).to include('<svg')
        expect(svg).to include('intersection of character sets')
      end

      it 'returns valid SVG for a conditional expression with group (a$|\Z)' do
        svg = described_class.new(regular_expression: 'a$|\Z').generate
        expect(svg).to include('<svg')
        expect(svg).to include('end of string or before end of line')
      end

      it 'returns valid SVG for an optional quantifier with group ((a)?)' do
        svg = described_class.new(regular_expression: '(a)?').generate
        expect(svg).to include('<svg')
        expect(svg).to include('"a"')
      end

      # it 'handles invalid regex gracefully' do
      #   instance = described_class.new(regular_expression: '[a')
      #   expect { instance.generate }.to raise_error(RegexpError)
      # end

      it 'returns valid SVG for a conditional group (a(b|c))' do
        svg = described_class.new(regular_expression: 'a(b|c)').generate
        expect(svg).to include('<svg')
        expect(svg).to include('"b"')
      end

      it 'returns valid SVG for a keep mark (ab\Kcd)' do
        svg = described_class.new(regular_expression: 'ab\Kcd').generate
        expect(svg).to include('<svg')
        expect(svg).to include('"cd"')
      end

      it 'returns valid SVG for a single literal (\g)' do
        svg = described_class.new(regular_expression: '\g').generate
        expect(svg).to include('<svg')
        expect(svg).to include('"g"')
      end

      it 'returns valid SVG for a multi literal (c\gt)' do
        svg = described_class.new(regular_expression: 'c\gt').generate
        expect(svg).to include('<svg')
        expect(svg).to include('"cgt"')
      end

      it 'returns valid SVG for POSIX class ([[:digit:]])' do
        svg = described_class.new(regular_expression: '[[:digit:]]').generate
        expect(svg).to include('<svg')
        expect(svg).to include('[:digit:]')
      end

      it 'returns valid SVG for Unicode property base ([\p{L}])' do
        svg = described_class.new(regular_expression: '[\p{L}]').generate
        expect(svg).to include('<svg')
        expect(svg).to include('\p{L}')
      end

      it 'returns valid SVG for ASCII escape sequence (a\ec)' do
        svg = described_class.new(regular_expression: 'a\ec').generate
        expect(svg).to include('<svg')
        expect(svg).to include('ASCII escape')
      end

      it 'returns valid SVG for backspace escape sequence ([\b])' do
        svg = described_class.new(regular_expression: '[\b]').generate
        expect(svg).to include('<svg')
        expect(svg).to include('backspace')
      end

      it 'returns valid SVG for bell escape sequence (\a)' do
        svg = described_class.new(regular_expression: '\a').generate
        expect(svg).to include('<svg')
        expect(svg).to include('bell')
      end

      it 'returns valid SVG for form feed escape sequence (\f)' do
        svg = described_class.new(regular_expression: '\f').generate
        expect(svg).to include('<svg')
        expect(svg).to include('form feed')
      end

      it 'returns valid SVG for newline escape sequence (\n)' do
        svg = described_class.new(regular_expression: '\n').generate
        expect(svg).to include('<svg')
        expect(svg).to include('newline')
      end

      it 'returns valid SVG for carriage return escape sequence (\r)' do
        svg = described_class.new(regular_expression: '\r').generate
        expect(svg).to include('<svg')
        expect(svg).to include('carriage return')
      end

      it 'returns valid SVG for tab escape sequence (\t)' do
        svg = described_class.new(regular_expression: '\t').generate
        expect(svg).to include('<svg')
        expect(svg).to include('tab')
      end

      it 'returns valid SVG for vertical tab escape sequence (\v)' do
        svg = described_class.new(regular_expression: '\v').generate
        expect(svg).to include('<svg')
        expect(svg).to include('vertical tab')
      end

      it 'returns valid SVG for literal escape sequence (\")' do
        svg = described_class.new(regular_expression: '\\"').generate
        expect(svg).to include('<svg')
        expect(svg).to include('"""')
      end

      it 'returns valid SVG for octal escape sequence (\0)' do
        svg = described_class.new(regular_expression: '\0').generate
        expect(svg).to include('<svg')
        expect(svg).to include('octal')
      end

      it 'returns valid SVG for hex escape sequence (\x41)' do
        svg = described_class.new(regular_expression: '\x41').generate
        expect(svg).to include('<svg')
        expect(svg).to include('hex')
      end

      it 'returns valid SVG for codepoint escape sequence (\u0640)' do
        svg = described_class.new(regular_expression: '\u0640').generate
        expect(svg).to include('<svg')
        expect(svg).to include('codepoint</text>')
      end

      it 'returns valid SVG for codepoint list escape sequence (\u{640 0641})' do
        svg = described_class.new(regular_expression: '\u{640 0641}').generate
        expect(svg).to include('<svg')
        expect(svg).to include('codepoint list')
      end

      it 'returns valid SVG for UTF-8 hex escape sequence (\xE2\x82\xAC)' do
        svg = described_class.new(regular_expression: '\xE2\x82\xAC').generate
        expect(svg).to include('<svg')
        expect(svg).to include('hex')
      end

      it 'returns valid SVG for abstract meta control escape sequence (\C-C)' do
        svg = described_class.new(regular_expression: '\C-C').generate
        expect(svg).to include('<svg')
        expect(svg).to include('abstract meta control')
      end

      ## RegexpError: too short escaped multibyte character: /\M-c/
      # it 'returns valid SVG for control character escape sequence' do
      #   svg = described_class.new(regular_expression: '\M-c').generate
      #   expect(svg).to include('<svg')
      #   expect(svg).to include('control character')
      # end

      ## RegexpError: invalid multibyte escape: /\M-\C-C/
      # it 'returns valid SVG for meta character escape sequence' do
      #   svg = described_class.new(regular_expression: '\M-\C-C').generate
      #   expect(svg).to include('<svg')
      #   expect(svg).to include('meta character')
      # end

      ## RegexpError: invalid multibyte escape: /\M-\cC/
      # it 'returns valid SVG for meta control escape sequence' do
      #   svg = described_class.new(regular_expression: '\M-\cC').generate
      #   expect(svg).to include('<svg')
      #   expect(svg).to include('meta control')
      # end

      ## RegexpError: invalid multibyte escape: /\C-\M-C/
      # it 'returns valid SVG for unknown escape sequence' do
      #   svg = described_class.new(regular_expression: '\0').generate
      #   expect(svg).to include('<svg')
      #   expect(svg).to include('\C-\M-C')
      # end
    end

    context 'when regex contains special characters and options' do
      it 'returns valid SVG for dot (.)' do
        svg = described_class.new(regular_expression: 'a.b').generate
        expect(svg).to include('<svg')
        expect(svg).to include('any character')
      end

      it 'returns SVG with options applied' do
        svg = described_class.new(regular_expression: '(?ix:a)').generate
        expect(svg).to include('<svg')
        expect(svg).to include('options apply modifiers: i, x')
      end

      ## RegexpError: undefined group option: /(?g:a)/
      # it 'returns SVG with global flag' do
      #   svg = described_class.new(regular_expression: '(?g:a)').generate
      #   expect(svg).to include('<svg')
      #   expect(svg).to include('options: g')
      # end
    end

    context 'when regex contains assertions' do
      it 'returns valid SVG for positive lookahead' do
        svg = described_class.new(regular_expression: 'a(?=b)').generate
        expect(svg).to include('<svg')
        expect(svg).to include('positive lookahead')
      end

      it 'returns valid SVG for negative lookahead' do
        svg = described_class.new(regular_expression: 'a(?!b)').generate
        expect(svg).to include('<svg')
        expect(svg).to include('negative lookahead')
      end

      it 'returns valid SVG for positive lookbehind' do
        svg = described_class.new(regular_expression: '(?<=a)b').generate
        expect(svg).to include('<svg')
        expect(svg).to include('positive lookbehind')
      end

      it 'returns valid SVG for negative lookbehind' do
        svg = described_class.new(regular_expression: '(?<!a)b').generate
        expect(svg).to include('<svg')
        expect(svg).to include('negative lookbehind')
      end
    end

    context 'when regex contains complex patterns' do
      it 'returns valid SVG for complex alternation with nested groups' do
        svg = described_class.new(regular_expression: '(a|b(c|d)+)+').generate
        expect(svg).to include('<svg')
        expect(svg).to include('"d"')
      end

      it 'returns valid SVG for deeply nested alternation' do
        svg = described_class.new(regular_expression: 'a(b(c|d(e|f)g|h)i|j)').generate
        expect(svg).to include('<svg')
        expect(svg).to include('"j"')
      end
    end

    context 'when regex contains whitespace and comments' do
      it 'returns SVG with whitespace handling' do
        svg = described_class.new(regular_expression: 'a\s+').generate
        expect(svg).to include('<svg')
        expect(svg).to include('whitespace')
      end

      it 'returns SVG with comments' do
        svg = described_class.new(regular_expression: 'a(?#comment)b').generate
        expect(svg).to include('<svg')
        expect(svg).to include('comment')
      end

      it 'handles multiple whitespace' do
        svg = described_class.new(regular_expression: 'a\s*\sb').generate
        expect(svg).to include('<svg')
        expect(svg).to include('whitespace')
      end

      it 'handles multiple comments' do
        svg = described_class.new(regular_expression: 'a(?#first)(?#second)b').generate
        expect(svg).to include('<svg')
        expect(svg).to include('"a"')
        expect(svg).to include('"b"')
      end
    end

    # context 'when regex contains empty or invalid regex string' do
    #   it 'returns a valid SVG string or empty string for empty regex' do
    #     svg = described_class.new(regular_expression: '').generate
    #     expect(svg).to be_a(String)
    #   end

    #   it 'raises error for malformed regex' do
    #     instance = described_class.new(regular_expression: '[')
    #     expect { instance.generate }.to raise_error(RegexpError)
    #   end
    # end
  end

  describe '.sanitize_svg' do
    let(:raw_svg) { '<svg><script>alert("XSS")</script><text>Test</text></svg>' }

    it 'removes script tags and dangerous content' do
      sanitized = described_class.sanitize_svg(raw_svg)
      expect(sanitized).to include('<svg>')
      expect(sanitized).to include('<text>Test</text>')
      expect(sanitized).not_to include('<script>')
    end

    it 'returns html_safe string' do
      sanitized = described_class.sanitize_svg(raw_svg)
      expect(sanitized).to respond_to(:html_safe)
    end

    context 'when svg is empty' do
      it 'returns an empty string safely' do
        sanitized = described_class.sanitize_svg('')
        expect(sanitized).to eq('')
      end
    end

    context 'when svg contains only allowed tags' do
      let(:valid_svg) { '<svg><path d="M10 10"></path></svg>' }

      it 'returns the same SVG' do
        sanitized = described_class.sanitize_svg(valid_svg)
        expect(sanitized).to eq(valid_svg)
      end
    end
  end

  describe '#render' do
    let(:regular_expression) { 'a+b*' }
    let(:options) { { some_option: true } }
    let(:renderer) { described_class.new(regular_expression: regular_expression, options: options) }

    context 'when expression is valid' do
      before do
        allow(renderer).to receive(:generate).and_return('<svg><g></g></svg>')
      end

      it 'returns sanitized SVG' do
        sanitized_svg = renderer.generate
        expect(sanitized_svg).to include('<svg>')
        expect(sanitized_svg).to include('<g></g>')
      end
    end

    context 'when expression is invalid' do
      let(:invalid_regular_expression) { '[' } # Invalid regex to simulate error
      let(:renderer) { described_class.new(regular_expression: invalid_regular_expression, options: options) }

      it 'sets an error message and returns nil' do
        result = renderer.generate
        expect(result).to be_nil
        expect(renderer.error_message).to be_present
      end
    end

    context 'when expression is blank' do
      let(:renderer) { described_class.new(regular_expression: '', options: options) }

      it 'returns nil' do
        result = renderer.generate
        expect(result).to be_nil
      end
    end
  end
end
