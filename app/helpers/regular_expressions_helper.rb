module RegularExpressionsHelper
  def regex_reference_sections
    [
      {
        title: "Character Classes & Anchors",
        col_class: "grid-cols-[80px_1fr]",
        items: [
          ["[abc]", "A single character of: a, b, or c"],
          ["[^abc]", "Any single character except: a, b, or c"],
          ["[a-z]", "Any single character in the range a-z"],
          ["[a-zA-Z]", "Any single character in the range a-z or A-Z"],
          ["^", "Start of line"],
          ["$", "End of line"],
          ['\\A', "Start of string"],
          ['\\z', "End of string"]
        ]
      },
      {
        title: "Common Patterns",
        col_class: "grid-cols-[30px_1fr]",
        items: [
          [".", "Any single character"],
          ['\\s', "Any whitespace character"],
          ['\\S', "Any non-whitespace character"],
          ['\\d', "Any digit"],
          ['\\D', "Any non-digit"],
          ['\\w', "Any word character (letter, number, underscore)"],
          ['\\W', "Any non-word character"],
          ['\\b', "Any word boundary"]
        ]
      },
      {
        title: "Groups & Quantifiers",
        col_class: "grid-cols-[60px_1fr]",
        items: [
          ["(...)", "Capture everything enclosed"],
          ["(a|b)", "a or b"],
          ["a?", "Zero or one of a"],
          ["a*", "Zero or more of a"],
          ["a+", "One or more of a"],
          ["a{3}", "Exactly 3 of a"],
          ["a{3,}", "3 or more of a"],
          ["a{3,6}", "Between 3 and 6 of a"]
        ]
      }
    ]
  end

  def regex_reference_options
    [
      ["i", "case insensitive"],
      ["m", "make dot match newlines"],
      ["x", "ignore whitespace in regex"]
    ]
  end

  def regexp_example_categories
    {
      "Basic operations" => {
        short: "Basics",
        description: "Basic operations: Concatenation, Alternation, Repeat (no syntax sugar).",
        examples: [

          # --- Concatenation ---
          { pattern: "abc", test: "abc", result: "match", options: "", description: "Concatenation: Matches 'a' + 'b' + 'c'" },
          { pattern: "ab", test: "cab", result: "match", options: "", description: "Concatenation: Matches 'ab' in the middle" },
          { pattern: "ab", test: "acb", result: "no match", options: "", description: "Concatenation: 'a' not followed by 'b'" },

          # --- Alternation ---
          { pattern: "a|b|c", test: "abc", result: "match", options: "", description: "Alternation: Matches one of 'a', 'b', or 'c'" },
          { pattern: "a|b*", test: "bbb", result: "match", options: "", description: "Alternation: Matches either 'a' or repeated 'b'" },
          { pattern: "a|b*", test: "aaa", result: "match", options: "", description: "Alternation: Matches either 'a' or repeated 'b'" },

          # --- Repeat ---
          { pattern: "a*", test: "a", result: "match", options: "", description: "Repeat: Matches one 'a'" },
          { pattern: "a*", test: "aaa", result: "match", options: "", description: "Repeat: Matches multiple 'a'" },
          { pattern: "a*", test: "bbb", result: "match", options: "", description: "Repeat: Matches zero 'a'" },

          # --- Combination ---
          { pattern: "ab|cd", test: "cd", result: "match", options: "", description: "Concatenation + Alternation: Matches 'ab' or 'cd'" },
          { pattern: "a|b*", test: "a", result: "match", options: "", description: "Alternation + Repeat: Matches 'a'" },
          { pattern: "a*bc", test: "aaabc", result: "match", options: "", description: "Concatenation + Repeat: 'a*' + 'b' + 'c'" }
        ]
      },

      "Syntax sugar" => {
        short: "Sugar",
        description: "Common syntax sugar features: quantifiers, dot, character classes, escapes, anchors.",
        examples: [

          # --- Quantifiers ---
          { pattern: "a+", test: "aaab", result: "match", options: "", description: "Quantifier '+': one or more 'a'" },
          { pattern: "a?", test: "apple", result: "match", options: "", description: "Quantifier '?': optional 'a'" },
          { pattern: "a{2,4}", test: "aaabc", result: "match", options: "", description: "Quantifier '{n,m}': 2 to 4 'a'" },

          # --- Dot ---
          { pattern: "a.c", test: "abc", result: "match", options: "", description: "Dot '.': matches any one character" },

          # --- Character classes ---
          { pattern: "[a-z]", test: "g", result: "match", options: "", description: "Character class: lowercase letter" },
          { pattern: "[a-z-]", test: "-", result: "match", options: "", description: "Character class: hyphen in range" },
          { pattern: "[^a-z]", test: "A", result: "match", options: "", description: "Negated class: not lowercase letter" },

          # --- Escape sequences ---
          { pattern: "a\\tb", test: "a\tb", result: "match", options: "", description: "Escape: tab character '\\t'" },

          # --- Anchors ---
          { pattern: "^a", test: "abc", result: "match", options: "", description: "Anchor '^': start of string" },
          { pattern: "c$", test: "abc", result: "match", options: "", description: "Anchor '$': end of string" },
          { pattern: "\\bword\\b", test: " word ", result: "match", options: "", description: "Anchor '\\b': word boundary" },
          { pattern: "\\Bend", test: "bend", result: "match", options: "", description: "Anchor '\\B': not at word boundary" }
        ]
      },

      "Alternations" => {
        short: "Alternations",
        description: "Alternations: Match one of several alternatives using the | operator.",
        examples: [
          { pattern: "cat|dog", test: "I have a cat", result: "match", options: "", description: "Matches 'cat' or 'dog'." },
          { pattern: "cat|dog", test: "I have a dog", result: "match", options: "", description: "Matches 'cat' or 'dog'." },
          { pattern: "cat|dog", test: "I have a bird", result: "no-match", options: "", description: "No match because neither 'cat' nor 'dog' is present." },
          { pattern: "red|green|blue", test: "green apple", result: "match", options: "", description: "Matches any of the listed colors." },
          { pattern: "red|green|blue", test: "yellow banana", result: "no-match", options: "", description: "No match since 'yellow' isn't an alternative." }
        ]
      },

      "Anchors" => {
        short: "Anchors",
        description: "Anchors: Match positions in the string using anchors like ^, $, \A, \b.",
        examples: [
          { pattern: "^start", test: "start here", result: "match", options: "", description: "Matches 'start' at the beginning." },
          { pattern: "^start", test: "this is start", result: "no-match", options: "", description: "No match because 'start' isn't at the start." },
          { pattern: "end$", test: "This is the end", result: "match", options: "", description: "Matches 'end' at the end." },
          { pattern: "end$", test: "end somewhere", result: "no-match", options: "", description: "No match because 'end' isn't at the end." },
          { pattern: "\\bword\\b", test: "The word is here", result: "match", options: "", description: "Matches 'word' as a separate word." },
          { pattern: "\\bhello\\b", test: "helloworld", result: "no-match", options: "", description: "No match because 'hello' isn't isolated by word boundaries." },
          { pattern: "\\Aabc", test: "abc anywhere", result: "match", options: "", description: "Matches 'abc' at the start." },
          { pattern: "\\Aabc", test: "this abc anywhere", result: "no-match", options: "", description: "No match because 'abc' isn't at the start." },
          { pattern: "xyz\\b", test: "xyzxyz", result: "match", options: "", description: "Matches 'xyz' because it's followed by a word boundary." },
          { pattern: "xyz\\b", test: "xyz is here", result: "match", options: "", description: "Matches 'xyz' at a word boundary." },
          { pattern: "start\\Z", test: "start", result: "match", options: "", description: "Matches 'start' at the end of the string." },
          { pattern: "start\\Z", test: "test start", result: "match", options: "", description: "Matches 'start' at the end of the string." }
        ]
      },

      "Character Classes" => {
        short: "Character Classes",
        description: "Character Classes: Match specific sets of characters inside square brackets.",
        examples: [
          { pattern: "[abc]", test: "a1bc", result: "match", options: "", description: "Matches 'a', 'b', 'c' because they are in the character class [abc]. '1' doesn't match." },
          { pattern: "[^abc]", test: "a1bc", result: "match", options: "", description: "Matches '1' because it's not in the character class [abc]. 'a', 'b', 'c' don't match." },
          { pattern: "[0-9]", test: "abc123", result: "match", options: "", description: "Matches '1', '2', '3' because they are digits in the range [0-9]. 'a', 'b', 'c' don't match." },
          { pattern: "[a-z]", test: "abc123", result: "match", options: "", description: "Matches 'a', 'b', 'c' because they are lowercase letters in the range [a-z]. '1', '2', '3' don't match." },
          { pattern: "[A-Z]", test: "abc123XYZ", result: "match", options: "", description: "Matches 'X', 'Y', 'Z' because they are uppercase letters in the range [A-Z]. 'a', 'b', 'c', '1', '2', '3' don't match." },
          { pattern: "[^\\\\]", test: "hello\\world", result: "match", options: "", description: "Matches '\\' because it's excluded in the class [^\\\\]. All other characters match." },
          { pattern: "[a-d&&aeiou]", test: "abcd123", result: "match", options: "", description: "Matches 'a' because it's in the range [a-d] and a vowel. 'b', 'c', 'd' don't match." },
          { pattern: "[a-d&&[^aeiou]]", test: "abcd123", result: "match", options: "", description: "Matches 'b' because it's in the range [a-d] and not a vowel. 'a', 'c', 'd' don't match." },
          { pattern: "[a=e=b]", test: "a", result: "match", options: "", description: "Matches 'a' because it's equivalent to 'e' and 'b' in the character class." }
        ]
      },

      "Character Types" => {
        short: "Character Types",
        description: "Character Types: Match specific character types like digits, whitespaces, etc.",
        examples: [
          { pattern: "\\d", test: "hello123", result: "match", options: "", description: "Matches '1', '2', '3' because they are digits." },
          { pattern: "\\d", test: "helloworld", result: "no-match", options: "", description: "No match because there are no digits in 'helloworld'." },
          { pattern: "\\H", test: "hello world", result: "match", options: "", description: "Matches all characters in 'hello world' because they are non-whitespace characters." },
          { pattern: "\\s", test: "hello world", result: "match", options: "", description: "Matches the space character between 'hello' and 'world'." },
          { pattern: "\\S", test: "hello world", result: "match", options: "", description: "Matches 'h', 'e', 'l', 'l', 'o', 'w', 'o', 'r', 'l', 'd' because they are non-space characters." },
          { pattern: "\\w", test: "helloworld123", result: "match", options: "", description: "Matches 'h', 'e', 'l', 'l', 'o', 'w', 'o', 'r', 'l', 'd', '1', '2', '3' because they are word characters." },
          { pattern: "\\w", test: "hello@world", result: "match", options: "", description: "Matches 'h', 'e', 'l', 'l', 'o', 'w', 'o', 'r', 'l', 'd' because they are word characters. '@' doesn't match." },
          { pattern: "\\W", test: "hello@world", result: "match", options: "", description: "Matches '@' because it's a non-word character." },
          { pattern: "\\W", test: "helloworld", result: "no-match", options: "", description: "No match because all characters are word characters." }
        ]
      },

      "Cluster Types" => {
        short: "Cluster Types",
        description: "Cluster Types: Match grapheme clusters using \R or \X.",
        examples: [
          { pattern: "\\R", test: "abc\n123", result: "match", options: "", description: "Matches the newline character between 'abc' and '123'." },
          { pattern: "\\R", test: "hello\rworld", result: "match", options: "", description: "Matches the carriage return between 'hello' and 'world'." },
          { pattern: "\\X", test: "👋", result: "match", options: "", description: "Matches the emoji '👋' as a single grapheme cluster." },
          { pattern: "\\X", test: "abc👋123", result: "match", options: "", description: "Matches the whole string as a single grapheme cluster, including the emoji '👋'." },
          { pattern: "\\X", test: "abc\u0301", result: "match", options: "", description: "Matches 'a' followed by an accent (combining character) as a single grapheme cluster." }
        ]
      },

      "Conditional Expressions" => {
        short: "Conditional Expressions",
        description: "Conditional Expressions: Match conditional patterns using (?(cond)yes-subexp|no-subexp).",
        examples: [
          { pattern: "(?<A>a)(?(<A>)T|F)", test: "aT", result: "match", options: "", description: "Matches 'T' because condition (<A>) is true." },
          { pattern: "(?<A>a)(?(<A>)T|)", test: "aT", result: "match", options: "", description: "Matches 'T' because condition (<A>) is true and empty branch is ignored." },
          { pattern: "(a)(?(001)T)", test: "aT", result: "match", options: "", description: "Matches 'T' because condition (001) is valid." }
        ]
      },

      "Escape Sequences" => {
        short: "Escape Sequences",
        description: "Escape Sequences: Match characters using escape sequences like \\t, \\n, \\d, etc.",
        examples: [
          { pattern: "\\t", test: "a\t", result: "match", options: "", description: "Matches the tab character." },
          { pattern: "\\n", test: "a\n", result: "match", options: "", description: "Matches the newline character." },
          { pattern: "\\d", test: "5", result: "match", options: "", description: "Matches a digit, here '5'." },
          { pattern: "\\d", test: "a", result: "no-match", options: "", description: "No match for 'a' because it's not a digit." },
          { pattern: "\\s", test: "a ", result: "match", options: "", description: "Matches a whitespace character (space)." },
          { pattern: "\\S", test: "a", result: "match", options: "", description: "Matches a non-whitespace character." },
          { pattern: "\\w", test: "a", result: "match", options: "", description: "Matches a word character, here 'a'." },
          { pattern: "\\W", test: "$", result: "match", options: "", description: "Matches a non-word character, here '$'." },
          { pattern: "\\b", test: "word", result: "match", options: "", description: "Matches the word boundary before 'word'." },
          { pattern: "\\B", test: "word", result: "no-match", options: "", description: "No match for 'word' because \\B matches non-word boundaries." },
          { pattern: "\\f", test: "a\f", result: "match", options: "", description: "Matches the form feed character." },
          { pattern: "\\r", test: "a\r", result: "match", options: "", description: "Matches the carriage return character." },
          { pattern: "\\0", test: "a\0", result: "match", options: "", description: "Matches the null character." },
          { pattern: "\\x41", test: "A", result: "match", options: "", description: "Matches the character 'A' using hexadecimal escape code." },
          { pattern: "\\\\+", test: "a\\", result: "match", options: "", description: "Matches one or more backslashes." },
          { pattern: "\\?", test: "?", result: "match", options: "", description: "Matches the literal question mark character." }
        ]
      },

      "Free Space" => {
        short: "Free Space",
        description: "Free Space: Match whitespace and comments using the x modifier.",
        examples: [
          { pattern: "a  # comment \nb", test: "ab", result: "match", options: "x", description: "Whitespace and comments are ignored, so 'a' and 'b' match." },
          { pattern: "  a  # word\n  b", test: "ab", result: "match", options: "x", description: "Whitespace and comment are ignored, so it matches 'ab'." },
          { pattern: "  a #word \nb", test: "ab", result: "match", options: "x", description: "Whitespace and comment are ignored, so it matches 'ab'." },
          { pattern: "   a   # starting\n   b", test: "ab", result: "match", options: "x", description: "Whitespace and comment are ignored, so 'ab' is matched." }
        ]
      },

      "Group Assertions" => {
        short: "Group Assertions",
        description: "Group assertions: Match positions without consuming characters using lookahead and lookbehind.",
        examples: [
          { pattern: "(?=abc)", test: "abc", result: "match", options: "", description: "Matches the position before 'abc'." },
          { pattern: "(?=\\w+)", test: "hello world", result: "match", options: "", description: "Matches the position before the word 'hello' because it's a word boundary." },
          { pattern: "(?!abc)", test: "xyz", result: "match", options: "", description: "Matches the position where 'abc' is not found." },
          { pattern: "(?<=abc)", test: "abcxyz", result: "match", options: "", description: "Matches the position after 'abc'." },
          { pattern: "(?<=\\d{3})", test: "123abc", result: "match", options: "", description: "Matches the position after a sequence of three digits." },
          { pattern: "(?<=\\b)", test: "hello", result: "match", options: "", description: "Matches the position after the word boundary before 'hello'." },
          { pattern: "(?<!abc)", test: "xyzabc", result: "match", options: "", description: "Matches the position before 'abc'." },
          { pattern: "(?<!\\d)", test: "abc123", result: "match", options: "", description: "Matches the position before 'abc' because it's not preceded by a digit." },
          { pattern: "(?<!\\d{2})", test: "abc123", result: "match", options: "", description: "Matches the position before 'abc' because it's not preceded by two digits." }
        ]
      },

      "Group Atomic" => {
        short: "Group Atomic",
        description: "Group Atomic: Atomic groups (?>...) match a subpattern without allowing backtracking within the group. If the overall match fails, the engine will not retry alternative paths inside the atomic group. This can reduce unnecessary backtracking and improve performance.",
        examples: [
          { pattern: "a(bc|b)c", test: "abc", result: "match", options: "", description: "Non-atomic: tries 'b', fails, backtracks and matches 'bc', then 'c'." },
          { pattern: "a(?>bc|b)c", test: "abc", result: "no-match", options: "", description: "Atomic: matches 'bc'; 'c' fails; no backtracking to 'b'." },
          { pattern: "(\\w+)\\d{3}", test: "user123", result: "match", options: "", description: "Matches 'user123'; captures 'user' in group 1; '123' is matched but not captured separately." },
          { pattern: "(?>\\w+)\\d{3}", test: "user123", result: "no-match", options: "", description: "No match because the atomic group (?>\\w+) greedily consumes 'user123', leaving nothing for \\d{3} to match." },
          { pattern: "Start(A+|A*B)End", test: "StartABEnd", result: "match", options: "", description: "Non-atomic: tries 'A+', fails; backtracks and tries 'A*B', which matches." },
          { pattern: "Start(?>A+|A*B)End", test: "StartABEnd", result: "no-match", options: "", description: "Atomic: greedily matches 'A+'; fails at 'B'; cannot try 'A*B'." }
        ]
      },

      "Group Absence" => {
        short: "Group Absence",
        description: "Group Absence: Absence operator (?~pattern) matches substrings that do NOT contain the pattern. When matching the entire string, it fails if the pattern exists anywhere. However, partial matches may occur on substrings excluding the pattern.",
        examples: [
          { pattern: "(?~abc)", test: "ab", result: "match", options: "", description: "Matches whole string; 'abc' is absent." },
          { pattern: "(?~abc)", test: "aab", result: "match", options: "", description: "Matches whole string; 'abc' is absent." },
          { pattern: "(?~abc)", test: "abb", result: "match", options: "", description: "Matches whole string; 'abc' is absent." },
          { pattern: "(?~abc)", test: "abc", result: "match", options: "", description: "Matches parts of the string that do not include 'abc' (e.g., 'ab', 'bc', or empty positions); full match is not possible." },
          { pattern: "^(?~abc)$", test: "abc", result: "no-match", options: "", description: "No match because the entire string contains 'abc', which is excluded by the absence group." },
          { pattern: "(?~abc)", test: "aabc", result: "match", options: "", description: "Partial match found excluding 'abc'; full string contains 'abc' so full match fails." },
          { pattern: "(?~abc)", test: "ccabcdd", result: "match", options: "", description: "Partial match on substrings excluding 'abc'; full string contains 'abc' so full match fails." },
          { pattern: "/\\*(?~\\*/)*\\*/", test: "/**/", result: "match", options: "", description: "Matches C-style empty comment." },
          { pattern: "/\\*(?~\\*/)*\\*/", test: "/* foo bar */", result: "match", options: "", description: "Matches C-style comment with content." }
        ]
      },

      "Group Back-references" => {
        short: "Group Back-references",
        description: "Group Back-references: Match the same text as previously captured using back-references.",
        examples: [
          { pattern: "(\\d)\\1", test: "11", result: "match", options: "", description: "Matches '11' because both digits are the same." },
          { pattern: "(?<word>\\w+)\\s\\k<word>", test: "hello hello", result: "match", options: "", description: "Matches 'hello hello' using a named back-reference." },
          { pattern: "(\\d+)\\k<1>", test: "123123", result: "match", options: "", description: "Matches '123123' using a numbered back-reference." },
          { pattern: "(\\w+)\\s\\1", test: "hello hello", result: "match", options: "", description: "Matches 'hello hello' because both words are the same." },
          { pattern: "(\\d{3})-(\\d{2})-(\\d{4})\\k<1>", test: "123-45-6789123", result: "match", options: "", description: "Matches '123-45-6789123' using a nested back-reference to the first group." },
          { pattern: "(\\w+)-(\\w+)\\k<2>", test: "apple-orangeorange", result: "match", options: "", description: "Matches 'apple-orangeorange' where the second group repeats using \k<2>." },
          { pattern: "(\\d{3})-(\\d{2})-(\\d{4})\\k<2>", test: "123-45-678945", result: "match", options: "", description: "Matches '123-45-678945' using a numbered back-reference to group 2." },
          { pattern: "(\\d+)\\1", test: "12345", result: "no-match", options: "", description: "No match for '12345' because the digits don't repeat." },
          { pattern: "(.)(.)\\k<-2>\\k<-1>", test: "xyzyz", result: "match", options: "", description: "Matches 'yzyz' where \\k<-2> and \\k<-1> refer to 2nd and 1st previous captures, respectively." }
        ]
      },

      "Group Capturing" => {
        short: "Group Capturing",
        description: "Group Capturing: Capture matched groups for later reference, accessible via numbered or named groups, including local variables after matching.",
        examples: [
          { pattern: "(abc)", test: "abc", result: "match", options: "", description: "Captures 'abc' in the first capturing group." },
          { pattern: "(\\d{2})-(\\d{2})-(\\d{4})", test: "12-34-5678", result: "match", options: "", description: "Captures the date parts into three groups: '12', '34', '5678'." },
          { pattern: "(\\w+)@(\\w+\\.\\w+)", test: "alice@example.com", result: "match", options: "", description: "Captures the username 'alice' and domain 'example.com' in two separate groups." },
          { pattern: "(\\d+)-(\\d+)", test: "123-456", result: "match", options: "", description: "Captures '123' in the first group and '456' in the second group." },
          { pattern: "(\\w{3})-(\\w{3})", test: "abc-def", result: "match", options: "", description: "Captures 'abc' in the first group and 'def' in the second group." },
          { pattern: "(\\d{4})(\\d{2})(\\d{2})", test: "20211225", result: "match", options: "", description: "Captures '2021', '12', '25' in three separate groups." },
          { pattern: "(\\w+)\\s(\\w+)", test: "hello world", result: "match", options: "", description: "Captures 'hello' in the first group and 'world' in the second group." },
          { pattern: "(\\w+)\\s+\\1", test: "hello hello", result: "match", options: "", description: "Captures 'hello' and matches it again using the same captured group." }
        ]
      },

      "Group Comments" => {
        short: "Group Comments",
        description: "Group Comments: Include comments inside regular expressions using (?# comment ).",
        examples: [
          { pattern: "(?# This is a comment)abc", test: "abc", result: "match", options: "", description: "Matches 'abc' while ignoring the comment." },
          { pattern: "a(?# matches 'a')b", test: "ab", result: "match", options: "", description: "Matches 'ab', ignoring the comment inside the parentheses." },
          { pattern: "(?#Start of string)^abc(?#End of string)$", test: "abc", result: "match", options: "", description: "Matches 'abc' at the start and end, while ignoring comments." },
          { pattern: "(?# a comment in the middle )ab(?# another comment)", test: "ab", result: "match", options: "", description: "Matches 'ab', ignoring comments in the middle." },
          { pattern: "(?# This pattern matches digits )\\d+", test: "12345", result: "match", options: "", description: "Matches one or more digits, ignoring the comment about digits." },
          { pattern: "(?# matches a space )\\s", test: " ", result: "match", options: "", description: "Matches a single space character while ignoring the comment." },
          { pattern: "(?# comment before and after )\\w{3,}", test: "word", result: "match", options: "", description: "Matches 'word' because it's a word of 3 or more characters, ignoring the comment." }
        ]
      },

      "Group Named" => {
        short: "Group Named",
        description: "Group Named: Capture groups with a specific name for easier reference.",
        examples: [
          { pattern: "(?<name>Alice)", test: "Alice", result: "match", options: "", description: "Captures 'abc' in a group named 'name'." },
          { pattern: "(?'name'Alice)", test: "Alice", result: "match", options: "", description: "Captures 'abc' in a group named 'name'." },
          { pattern: "(?P<name>Alice)", test: "Alice", result: "no-match", options: "", description: "Python-style named group syntax '(?P<name>...)' is not supported in Ruby, so no match." },
          { pattern: "(?<year>\\d{4})-(?'month'\\d{2})-(?'day'\\d{2})", test: "2023-07-25", result: "match", options: "", description: "Captures the year, month, and day into named groups." },
          { pattern: "(?<hour>\\d{2}):(?'minute'\\d{2})", test: "14:30", result: "match", options: "", description: "Captures hour and minute into named groups." },
          { pattern: "(?<user>\\w+)@(?<domain>\\w+\\.\\w+)", test: "alice@example.com", result: "match", options: "", description: "Captures 'alice' in the named group 'alice' and 'example.com' in the named group 'domain'." },
          { pattern: "\\$(?<dollars>\\d+)\\.(?<cents>\\d+)", test: "$3.67", result: "match", options: "", description: "Captures dollars and cents into named groups 'dollars' and 'cents', accessible via MatchData with symbol keys." },
          { pattern: "(?<vowel>[aeiou]).\\k<vowel>.\\k<vowel>", test: "ototomy", result: "match", options: "", description: "Uses named capture and back-references to match repeated vowels." },
          { pattern: "(?<name>\\w+)(\\d{3})", test: "user123", result: "match", options: "", description: "Matches successfully; named capture 'name' and numbered capture both exist, but MatchData mainly exposes named captures." }
        ]
      },

      "Group Options" => {
        short: "Group Options",
        description: "Group Options: Modify regex behavior using inline options like (?i), (?m), etc.",
        examples: [
          { pattern: "(?i)abc", test: "ABC", result: "match", options: "", description: "Matches 'ABC' case-insensitively due to the (?i) option." },
          { pattern: "(?m)^abc", test: "abc\nabc", result: "match", options: "", description: "Matches 'abc' at the start of each line due to the (?m) multiline option." },
          { pattern: "(?x) a # space is ignored\nb", test: "ab", result: "match", options: "", description: "Matches 'ab' while ignoring the space and comment due to the (?x) extended option." },
          { pattern: "(?i)hello(?-i)world", test: "HELLOworld", result: "match", options: "", description: "Matches 'HELLO' case-insensitively and 'world' case-sensitively due to inline options." },
          { pattern: "(?i)(abc)(?-i)def", test: "ABCdef", result: "match", options: "", description: "Matches 'ABC' case-insensitively and 'def' case-sensitively." },
          { pattern: "(?m)\\bstart\\b", test: "start\nstart", result: "match", options: "", description: "Matches 'start' at the beginning of each line due to the (?m) option." },
          { pattern: "(?x) a # space is ignored\nc", test: "ac", result: "match", options: "", description: "Matches 'ac' while ignoring the comment and spaces due to the (?x) option." }
        ]
      },

      "Group Passive" => {
        short: "Group Passive",
        description: "Group Passive: Create a non-capturing group that doesn't store matches.",
        examples: [
          { pattern: "(?:abc)", test: "abc", result: "match", options: "", description: "Non-capturing group for 'abc'." },
          { pattern: "(?:\\d{2})-(?:\\d{2})-(?:\\d{4})", test: "12-34-5678", result: "match", options: "", description: "Non-capturing groups for the date pattern." },
          { pattern: "(?:\\w+)@(\\w+\\.\\w+)", test: "alice@example.com", result: "match", options: "", description: "Captures domain but ignores the username using passive group." }
        ]
      },

      "Group Subexpression Calls" => {
        short: "Group Subexp. Calls",
        description: "Group Subexp. Calls: Call a previously defined subexpression (either by name or index).",
        examples: [
          { pattern: "(abc)\\g<1>", test: "abcabc", result: "match", options: "", description: "Refers to the first captured group." },
          { pattern: "(?<name>hello)\\g<name>", test: "hellohello", result: "match", options: "", description: "Refers to the group named 'name'." },
          { pattern: "(abc)(def)\\g<1>\\g<2>", test: "abcdefabcdef", result: "match", options: "", description: "Refers to two captured groups by index." }
        ]
      },

      "Keep" => {
        short: "Keep",
        description: "Keep: Keep the current match and resume matching after it using \\K.",
        examples: [
          { pattern: "ab\\Kcd", test: "abcdef", result: "match", options: "", description: "Matches 'cd' after 'ab' is discarded using \\K." },
          { pattern: "a\\Kb", test: "abc", result: "match", options: "", description: "Matches 'b' after 'a' is discarded using \\K." },
          { pattern: "foo\\Kbar", test: "foobar", result: "match", options: "", description: "Matches 'bar' after 'foo' is discarded using \\K." },
          { pattern: "xyz\\Kabc", test: "xyzabc", result: "match", options: "", description: "Matches 'abc' after 'xyz' is discarded using \\K." },
          { pattern: "start\\Kend", test: "startend", result: "match", options: "", description: "Matches 'end' after 'start' is discarded using \\K." },
          { pattern: "one\\Ktwo", test: "one two", result: "match", options: "", description: "Matches 'two' after 'one' is discarded using \\K." },
          { pattern: "aaa\\Kbbb", test: "aaabbb", result: "match", options: "", description: "Matches 'bbb' after 'aaa' is discarded using \\K." },
          { pattern: "1\\K2", test: "12", result: "match", options: "", description: "Matches '2' after '1' is discarded using \\K." },
          { pattern: "abc\\Kxyz", test: "abcxyz", result: "match", options: "", description: "Matches 'xyz' after 'abc' is discarded using \\K." },
          { pattern: "quick\\Kbrown", test: "quickbrown", result: "match", options: "", description: "Matches 'brown' after 'quick' is discarded using \\K." }
        ]
      },

      "Literals" => {
        short: "Literals",
        description: "Literals: Match specific literal characters including Unicode characters.",
        examples: [
          { pattern: "Ruby", test: "Ruby", result: "match", options: "", description: "Matches 'Ruby' exactly." },
          { pattern: "apple", test: "apple pie", result: "match", options: "", description: "Matches 'apple' exactly in 'apple pie'." },
          { pattern: "dog", test: "doghouse", result: "match", options: "", description: "Matches 'dog' exactly in 'doghouse'." },
          { pattern: "123", test: "1234", result: "match", options: "", description: "Matches '123' exactly in '1234'." },
          { pattern: "abc", test: "abcdef", result: "match", options: "", description: "Matches 'abc' exactly in 'abcdef'." },
          { pattern: "😃", test: "I am happy 😃", result: "match", options: "", description: "Matches the exact emoji '😃'." },
          { pattern: "ルビー", test: "私はルビーが好きです", result: "match", options: "", description: "Matches the exact Japanese word 'ルビー'." },
          { pattern: "روبي", test: "اسمي روبي", result: "match", options: "", description: "Matches the exact Arabic word 'روبي'." },
          { pattern: "apple", test: "applepie", result: "no-match", options: "", description: "No match for 'apple' because the word is attached to 'pie'." },
          { pattern: "dog", test: "god", result: "no-match", options: "", description: "No match for 'dog' because the letters are in a different order." },
          { pattern: "🌍", test: "world 🌍", result: "match", options: "", description: "Matches the exact emoji '🌍'." }
        ]
      },

      "POSIX Classes" => {
        short: "POSIX Classes",
        description: "POSIX Classes: Match POSIX character classes like [:alpha:], [:digit:], etc. Can also use negation (e.g., [:^alpha:]) to match non-characters.",
        examples: [
          # --- Alphabetic Characters ---
          { pattern: "[[:alpha:]]+", test: "abc123XYZ", result: "match", options: "", description: "Matches 'abc' and 'XYZ', skips digits." },
          { pattern: "[[:^alpha:]]+", test: "abc123XYZ", result: "match", options: "", description: "Matches digits '123', skips alphabetic chars." },

          # --- Digit Characters ---
          { pattern: "[[:digit:]]+", test: "abc123.45def", result: "match", options: "", description: "Matches digit sequences '123' and '45'." },

          # --- Punctuation Characters ---
          { pattern: "[[:punct:]]+", test: "hello!?", result: "match", options: "", description: "Matches punctuation '!?'." },

          # --- Whitespace Characters ---
          { pattern: "[[:space:]]+", test: "a b\tc\n", result: "match", options: "", description: "Matches spaces, tabs, and newlines." },

          # --- Case Sensitivity ---
          { pattern: "[[:lower:]]+", test: "AbC", result: "match", options: "", description: "Matches lowercase 'b' only." },
          { pattern: "[[:upper:]]+", test: "AbC", result: "match", options: "", description: "Matches uppercase 'A' and 'C'." }
        ]
      },

      "Quantifiers Greedy" => {
        short: "Quantifiers Greedy",
        description: "Greedy quantifiers: Match as many times as possible.",
        examples: [
          { pattern: "a*", test: "abc123!", result: "match", options: "", description: "Matches zero or more 'a's greedily; matches '' or 'a' at start." },
          { pattern: "a*", test: "aaaabc123!", result: "match", options: "", description: "Matches all leading 'a's greedily." },
          { pattern: "a+", test: "abc123!", result: "match", options: "", description: "Matches one or more 'a's greedily; matches first 'a'." },
          { pattern: "a{2}", test: "abc123!", result: "no-match", options: "", description: "No match; requires exactly two 'a's." },
          { pattern: "(abc)*", test: "abc123!", result: "match", options: "", description: "Matches zero or more 'abc's greedily; matches one 'abc'." },
          { pattern: "(abc)+", test: "abc123!", result: "match", options: "", description: "Matches one or more 'abc's greedily." },
          { pattern: "(abc)?", test: "abc123!", result: "match", options: "", description: "Matches zero or one 'abc' greedily." },
          { pattern: "(abc){2}", test: "abcabc123!", result: "match", options: "", description: "Matches exactly two 'abc' sequences greedily." },
          { pattern: "(abc){2,3}", test: "abcabc123!", result: "match", options: "", description: "Matches 2 to 3 'abc's greedily (matches 2)." },
          { pattern: "(abc){2,3}", test: "abcabcabc123!", result: "match", options: "", description: "Matches 2 to 3 'abc's greedily (matches 3)." }
        ]
      },

      "Quantifiers Reluctant (Lazy)" => {
        short: "Quantifiers Reluctant (Lazy)",
        description: "Reluctant (Lazy) quantifiers: Match as few times as possible.",
        examples: [
          { pattern: "a*?", test: "abc123!", result: "match", options: "", description: "Matches zero or more 'a's lazily; prefers empty match." },
          { pattern: "a*?", test: "aaaabc123!", result: "match", options: "", description: "Matches zero 'a's lazily at start." },
          { pattern: "a+?", test: "abc123!", result: "match", options: "", description: "Matches one or more 'a's lazily; matches one 'a'." },
          { pattern: "a{2}?", test: "abc123!", result: "no-match", options: "", description: "No match; requires exactly two 'a's." },
          { pattern: "(abc)*?", test: "abc123!", result: "match", options: "", description: "Matches zero 'abc's lazily at start." },
          { pattern: "(abc)+?", test: "abc123!", result: "match", options: "", description: "Matches one 'abc' lazily." },
          { pattern: "(abc)?", test: "abc123!", result: "match", options: "", description: "Matches zero or one 'abc' lazily." },
          { pattern: "(abc){2}?", test: "abcabc123!", result: "match", options: "", description: "Matches exactly two 'abc' sequences lazily." },
          { pattern: "(abc){2,3}?", test: "abcabc123!", result: "match", options: "", description: "Matches 2 'abc's lazily." },
          { pattern: "(abc){2,3}?", test: "abcabcabc123!", result: "match", options: "", description: "Matches 2 'abc's lazily; stops early." }
        ]
      },

      "Quantifiers Possessive" => {
        short: "Quantifiers Possessive",
        description: "Possessive quantifiers: Match as many times as possible without backtracking.",
        examples: [
          { pattern: "a*+", test: "abc123!", result: "match", options: "", description: "Matches zero or more 'a's possessively; no backtracking." },
          { pattern: "a*+", test: "aaaabc123!", result: "match", options: "", description: "Matches all leading 'a's possessively." },
          { pattern: "a++", test: "abc123!", result: "match", options: "", description: "Matches one or more 'a's possessively." },
          { pattern: "a{2}+", test: "abc123!", result: "no-match", options: "", description: "No match; requires exactly two 'a's possessively." },
          { pattern: "(abc)*+", test: "abc123!", result: "match", options: "", description: "Matches zero or more 'abc's possessively." },
          { pattern: "(abc)++", test: "abc123!", result: "match", options: "", description: "Matches one or more 'abc's possessively." },
          { pattern: "(abc)?+", test: "abc123!", result: "match", options: "", description: "Matches zero or one 'abc' possessively." },
          { pattern: "(abc){2}+", test: "abcabc123!", result: "match", options: "", description: "Matches exactly two 'abc' sequences possessively." },
          { pattern: "(abc){2,3}+", test: "abcabc123!", result: "match", options: "", description: "Matches 2 to 3 'abc's possessively." },
          { pattern: "(abc){2,3}+", test: "abcabcabc123!", result: "match", options: "", description: "Matches 2 to 3 'abc's possessively." }
        ]
      },

      "String Escapes" => {
        short: "String Escapes",
        description: "String Escapes: Match special characters using escape sequences like \d, \w, \s, etc.",
        examples: [
          { pattern: "\\d", test: "123abc", result: "match", options: "", description: "Matches '1' because \\d matches any digit." },
          { pattern: "\\d", test: "abc123", result: "no-match", options: "", description: "No match because there is no digit at the beginning." },
          { pattern: "\\w", test: "abc123", result: "match", options: "", description: "Matches 'a' because \\w matches a word character." },
          { pattern: "\\w", test: "123!@#", result: "match", options: "", description: "Matches '1' because \\w matches a word character (digit)." },
          { pattern: "\\W", test: "!@#", result: "match", options: "", description: "Matches '!' because \\W matches non-word characters." },
          { pattern: "\\s", test: "abc def", result: "match", options: "", description: "Matches ' ' (space) because \\s matches any whitespace character." },
          { pattern: "\\S", test: "abc def", result: "match", options: "", description: "Matches 'a' because \\S matches any non-whitespace character." },
          { pattern: "\\b", test: "hello world", result: "match", options: "", description: "Matches the boundary between 'hello' and 'world'." },
          { pattern: "\\B", test: "abc123", result: "match", options: "", description: "Matches 'b' because \\B matches a non-word boundary between 'a' and 'b'." },
          { pattern: "\\x20", test: "abc 123", result: "match", options: "", description: "Matches '\\x20' (hexadecimal code for space)." },
          { pattern: "\\u{1F60D}", test: "I love emojis 😍", result: "match", options: "", description: "Matches the emoji '😍' using Unicode escape sequence." }
        ]
      },

      "Unicode Age" => {
        short: "Unicode Age",
        description: "Match characters by Unicode version (Age). Supports \\p{Age}, \\P{Age}, and caret negation.",
        examples: [
          { pattern: "\\p{Age=5.2}+", test: "🤩☆あ", result: "match", options: "", description: "Match emoji 🤩 from Age 5.2, stops before star '☆'" },
          { pattern: "\\P{Age=6.1}+", test: "Aあ🤔", result: "match", options: "", description: "Match chars not in Age 6.1, stops before emoji" },
          { pattern: "\\p{Age=3.0}+", test: "¡¿D", result: "match", options: "", description: "Match punctuation from Age 3.0, stops before 'D'" },
          { pattern: "\\P{Age=5.2}+", test: "ABC🤩", result: "match", options: "", description: "Matches 'ABC', stops before Age 5.2 emoji 🤩" },
          { pattern: "\\p{Age=7.0}+", test: "𝄞C", result: "match", options: "", description: "Matches musical symbol (Age 7.0), stops before 'C'" },
          { pattern: "\\P{Age=8.0}+", test: "abc🧭", result: "match", options: "", description: "Matches 'abc', stops before Age 8.0 compass emoji 🧭" }
        ]
      },

      "Unicode Blocks" => {
        short: "Unicode Blocks",
        description: "Match by Unicode block. Use \\p{In…}, \\P{In…}, or caret negation.",
        examples: [
          { pattern: "\\p{InKatakana}+", test: "カタカナあA", result: "match", options: "", description: "Match Katakana chars, stops before Hiragana 'あ'" },
          { pattern: "\\p{InArmenian}+", test: "ԱԲԳՖabc", result: "match", options: "", description: "Match Armenian letters, stops before Latin 'abc'" },
          { pattern: "\\P{InThai}+", test: "Helloกส", result: "match", options: "", description: "Match non-Thai chars 'Hello', stops before Thai" },
          { pattern: "\\p{^InKhmer}+", test: "xyzខ", result: "match", options: "", description: "Match chars not in Khmer, stops at Khmer char" },
          { pattern: "\\p{InCyrillic}+", test: "ПриветX", result: "match", options: "", description: "Match Cyrillic letters, stops before Latin 'X'" },
          { pattern: "\\P{InHebrew}+", test: "ABCשלום", result: "match", options: "", description: "Match non-Hebrew chars, stops before Hebrew letters" }
        ]
      },

      "Unicode Classes" => {
        short: "Unicode Classes",
        description: "Binary and negated properties like Alpha, Space, Alnum.",
        examples: [
          { pattern: "\\p{Alpha}+", test: "Hi1!", result: "match", options: "", description: "Match alphabetic letters, stops before digit" },
          { pattern: "\\P{Space}+", test: "Az BC", result: "match", options: "", description: "Match non-space chars 'Az', stops before space" },
          { pattern: "\\p{^Alnum}+", test: "abc-123?", result: "match", options: "", description: "Match chars not alphanumeric, stops before letters/digits" },
          { pattern: "\\p{Digit}+", test: "123a", result: "match", options: "", description: "Match digits only, stops before letter" },
          { pattern: "\\P{Alpha}+", test: "123A", result: "match", options: "", description: "Match non-alphabetic chars, stops before 'A'" },
          { pattern: "\\p{Space}+", test: "a b", result: "match", options: "", description: "Match spaces only, stops before 'b'" }
        ]
      },

      "Unicode Derived" => {
        short: "Unicode Derived",
        description: "Derived properties such as Math, Lowercase, Cased.",
        examples: [
          { pattern: "\\p{Math}+", test: "+×= x", result: "match", options: "", description: "Match math symbols, stops before space" },
          { pattern: "\\P{Lowercase}+", test: "ABCdef", result: "match", options: "", description: "Match non-lowercase, stops before 'd'" },
          { pattern: "\\p{^Cased}+", test: "123_a", result: "match", options: "", description: "Match non-cased chars, stops before 'a'" },
          { pattern: "\\p{Lowercase}+", test: "abcD", result: "match", options: "", description: "Match lowercase letters, stops before uppercase" },
          { pattern: "\\P{Math}+", test: "abc+=", result: "match", options: "", description: "Match non-math chars, stops before math symbols" },
          { pattern: "\\p{Alphabetic}+", test: "ab1", result: "match", options: "", description: "Match alphabetic chars, stops before digit" }
        ]
      },

      "Unicode General Categories" => {
        short: "Unicode General Categories",
        description: "Categories like Lu, Cs, and negated script (sc).",
        examples: [
          { pattern: "\\p{LU}+", test: "ABCd", result: "match", options: "", description: "Uppercase abbreviation 'LU' matches uppercase letters" },
          { pattern: "\\p{lu}+", test: "ABCd", result: "match", options: "", description: "Lowercase abbreviation 'lu' matches uppercase letters" },
          { pattern: "\\p{Uppercase Letter}+", test: "ABCd", result: "match", options: "", description: "Full property name with space matches uppercase letters" },
          { pattern: "\\p{Uppercase_Letter}+", test: "ABCd", result: "match", options: "", description: "Full property name with underscore matches uppercase letters" },
          { pattern: "\\p{UPPERCASE-LETTER}+", test: "ABCd", result: "match", options: "", description: "Full property name with hyphen and uppercase letters matches uppercase letters" },
          { pattern: "\\P{Lu}+", test: "ABCd", result: "match", options: "", description: "Match non-uppercase, stops before uppercase" },
          { pattern: "\\p{^sc}+", test: "123Λ", result: "match", options: "", description: "Match chars without script, stops before Greek" },
          { pattern: "\\p{Cc}+", test: "\u0001A", result: "match", options: "", description: "Match control characters, stops before 'A'" },
          { pattern: "\\p{Cf}+", test: "\u200DA", result: "match", options: "", description: "Match format characters, stops before 'A'" }
        ]
      },

      "Unicode Scripts" => {
        short: "Unicode Scripts",
        description: "Script property match, with negation.",
        examples: [
          { pattern: "\\p{Arabic}+", test: "سلامHello", result: "match", options: "", description: "Match Arabic script, stops before Latin text" },
          { pattern: "\\P{Hiragana}+", test: "ABCあいう", result: "match", options: "", description: "Match non-Hiragana chars, stops before Hiragana" },
          { pattern: "\\p{^Greek}+", test: "ABCΩΔ", result: "match", options: "", description: "Match non-Greek chars, stops before Greek" },
          { pattern: "\\p{Katakana}+", test: "カタカナB", result: "match", options: "", description: "Match Katakana script, stops before Latin" },
          { pattern: "\\p{Cyrillic}+", test: "ПриветX", result: "match", options: "", description: "Match Cyrillic script, stops before Latin" },
          { pattern: "\\P{Devanagari}+", test: "Helloनमस्ते", result: "match", options: "", description: "Match non-Devanagari chars, stops before Devanagari" }
        ]
      },

      "Unicode Simple Props" => {
        short: "Unicode Simple Props",
        description: "Simple binary properties like Dash, Extender, and negation.",
        examples: [
          { pattern: "\\p{Dash}+", test: "–‑—A", result: "match", options: "", description: "Match dash characters, stops before 'A'" },
          { pattern: "\\p{Extender}+", test: "ːX", result: "match", options: "", description: "Matches extender letter ː, stops before 'X'" },
          { pattern: "\\p{^Hyphen}+", test: "word-word", result: "match", options: "", description: "Match chars except hyphen, stops at hyphen" },
          { pattern: "\\P{Dash}+", test: "ABC–", result: "match", options: "", description: "Match non-dash chars, stops before dash" },
          { pattern: "\\p{Hyphen}+", test: "-B", result: "match", options: "", description: "Match hyphen char, stops before 'B'" },
          { pattern: "\\p{Emoji}+", test: "👨‍👩‍👧‍👦abc", result: "match", options: "", description: "Matches emoji family, stops before 'abc'" }
        ]
      },

      "POSIX Classes vs Unicode Properties" => {
        short: "POSIX vs Unicode",
        description: "Compare POSIX character classes and Unicode property constructs with clear match boundaries.",
        examples: [
          # --- Alphabetic Characters ---
          { pattern: "[[:alpha:]]+", test: "abc123XYZ", result: "match", options: "", description: "POSIX alpha: matches 'abc' and 'XYZ', skips '123'" },
          { pattern: "\\p{Alpha}+", test: "abc123XYZ", result: "match", options: "", description: "Unicode Alpha: matches 'abc' and 'XYZ', skips '123'" },
          { pattern: "[[:^alpha:]]+", test: "abc123XYZ", result: "match", options: "", description: "POSIX negated alpha: matches '123', skips letters" },
          { pattern: "\\P{Alpha}+", test: "abc123XYZ", result: "match", options: "", description: "Unicode non-Alpha: matches '123', skips alphabetic" },

          # --- Digit Characters ---
          { pattern: "[[:digit:]]+", test: "abc123.45def", result: "match", options: "", description: "POSIX digit: matches '123' and '45'" },
          { pattern: "\\p{Digit}+", test: "abc123.45def", result: "match", options: "", description: "Unicode Digit: matches '123' and '45'" },

          # --- Punctuation ---
          { pattern: "[[:punct:]]+", test: "hello!?", result: "match", options: "", description: "POSIX punct: matches '!?'" },
          { pattern: "\\p{Punct}+", test: "hello!?", result: "match", options: "", description: "Unicode Punct: matches '!?' (punctuation)" },

          # --- Whitespace ---
          { pattern: "[[:space:]]+", test: "a b\tc\n", result: "match", options: "", description: "POSIX space: matches space, tab, newline" },
          { pattern: "\\p{Space}+", test: "a b\tc\n", result: "match", options: "", description: "Unicode Space: matches space, tab, newline" },

          # --- Case Sensitivity ---
          { pattern: "[[:lower:]]+", test: "AbC", result: "match", options: "", description: "POSIX lower: matches 'b'" },
          { pattern: "\\p{Lower}+", test: "AbC", result: "match", options: "", description: "Unicode Lower: matches 'b'" },
          { pattern: "[[:upper:]]+", test: "AbC", result: "match", options: "", description: "POSIX upper: matches 'A' and 'C'" },
          { pattern: "\\p{Upper}+", test: "AbC", result: "match", options: "", description: "Unicode Upper: matches 'A' and 'C'" }

        ]
      }
    }
  end
end
