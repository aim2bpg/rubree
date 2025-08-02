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
      "Alternation" => {
        short: "Alt",
        description: "Match alternatives separated by |.",
        examples: [
          { pattern: "a|b|c", test: "apple", result: "match", options: "", description: "Matches 'a' because 'apple' contains 'a', which is one of the alternatives." },
          { pattern: "a|b|c", test: "ab", result: "match", options: "", description: "Matches 'ab' because 'a' and 'b' are part of the alternatives." },
          { pattern: "red|blue|green", test: "blueberry", result: "match", options: "", description: "Matches 'blue' because 'blueberry' contains 'blue'." },
          { pattern: "red|blue|green", test: "Blueberry", result: "no-match", options: "", description: "No match for 'Blueberry' because 'blue' is case-sensitive." },
          { pattern: "dog|cat|rat", test: "dog cat", result: "match", options: "", description: "Matches 'dog' and 'cat' because they are part of the alternatives." },
          { pattern: "dog|cat|rat", test: "cat and rat", result: "match", options: "", description: "Matches 'cat' and 'rat' because both are part of the alternatives." }
        ]
      },

      "Anchors" => {
        short: "Anc",
        description: "Match positions in the string using anchors like ^, $, \A, \b.",
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
        short: "CharCls",
        description: "Match specific sets of characters inside square brackets.",
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
        short: "CharType",
        description: "Match specific character types like digits, whitespaces, etc.",
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
        short: "ClsType",
        description: "Match grapheme clusters using \R or \X.",
        examples: [
          { pattern: "\\R", test: "abc\n123", result: "match", options: "", description: "Matches the newline character between 'abc' and '123'." },
          { pattern: "\\R", test: "hello\rworld", result: "match", options: "", description: "Matches the carriage return between 'hello' and 'world'." },
          { pattern: "\\X", test: "👋", result: "match", options: "", description: "Matches the emoji '👋' as a single grapheme cluster." },
          { pattern: "\\X", test: "abc👋123", result: "match", options: "", description: "Matches the whole string as a single grapheme cluster, including the emoji '👋'." },
          { pattern: "\\X", test: "abc\u0301", result: "match", options: "", description: "Matches 'a' followed by an accent (combining character) as a single grapheme cluster." }
        ]
      },

      "Conditional Expressions" => {
        short: "Cond",
        description: "Match conditional patterns using (?(cond)yes-subexp|no-subexp).",
        examples: [
          { pattern: "(?<A>a)(?(<A>)T|F)", test: "aT", result: "match", options: "", description: "Matches 'T' because condition (<A>) is true." },
          { pattern: "(?<A>a)(?(<A>)T|)", test: "aT", result: "match", options: "", description: "Matches 'T' because condition (<A>) is true and empty branch is ignored." },
          { pattern: "(a)(?(001)T)", test: "aT", result: "match", options: "", description: "Matches 'T' because condition (001) is valid." }
        ]
      },

      "Escape Sequences" => {
        short: "EscSeq",
        description: "Match characters using escape sequences like \\t, \\n, \\d, etc.",
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
        short: "FreeSpc",
        description: "Match whitespace and comments using the x modifier.",
        examples: [
          { pattern: "a  # comment \nb", test: "ab", result: "match", options: "x", description: "Whitespace and comments are ignored, so 'a' and 'b' match." },
          { pattern: "  a  # word\n  b", test: "ab", result: "match", options: "x", description: "Whitespace and comment are ignored, so it matches 'ab'." },
          { pattern: "  a #word \nb", test: "ab", result: "match", options: "x", description: "Whitespace and comment are ignored, so it matches 'ab'." },
          { pattern: "   a   # starting\n   b", test: "ab", result: "match", options: "x", description: "Whitespace and comment are ignored, so 'ab' is matched." }
        ]
      },

      "Assertions" => {
        short: "GAst",
        description: "Match positions without consuming characters using lookahead and lookbehind.",
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

      "Atomic" => {
        short: "GAtm",
        description: "Ensure that a subexpression matches atomically without backtracking using (?>...).",
        examples: [
          { pattern: "(?>abc)", test: "abc", result: "match", options: "", description: "Matches 'abc' atomically, no backtracking allowed." },
          { pattern: "(?>a|b)c", test: "ac", result: "match", options: "", description: "Matches 'a' atomically, followed by 'c'. No backtracking to match 'b'." },
          { pattern: "(?>a|b)c", test: "bc", result: "match", options: "", description: "Matches 'b' atomically, followed by 'c'. No backtracking to match 'a'." },
          { pattern: "(?>a|b)c", test: "cc", result: "no-match", options: "", description: "No match for 'cc' because 'a' or 'b' are required before 'c'." },
          { pattern: "(?>a|b|c)d", test: "cd", result: "match", options: "", description: "Matches 'c' atomically, followed by 'd'. No backtracking to match 'a' or 'b'." },
          { pattern: "(?>a|b|c)d", test: "ad", result: "match", options: "", description: "Matches 'a' atomically, followed by 'd'. No backtracking to match 'b' or 'c'." },
          { pattern: "(?>a|b|c)d", test: "bd", result: "match", options: "", description: "Matches 'b' atomically, followed by 'd'. No backtracking to match 'a' or 'c'." },
          { pattern: "(?>abc|def)ghi", test: "abcghi", result: "match", options: "", description: "Matches 'abc' atomically, followed by 'ghi'. No backtracking to match 'def'." }
        ]
      },

      "Absence" => {
        short: "GAbs",
        description: "Match the absence of a subexpression using (?~...).",
        examples: [
          { pattern: "(?~abc)", test: "xyz", result: "match", options: "", description: "Matches 'xyz' because 'abc' is absent." },
          { pattern: "(?~123)", test: "456", result: "match", options: "", description: "Matches '456' because '123' is absent." },
          { pattern: "(?~abc)", test: "ab", result: "match", options: "", description: "Matches 'ab' because 'abc' is absent." },
          { pattern: "(?~cat)", test: "dog", result: "match", options: "", description: "Matches 'dog' because 'cat' is absent." },
          { pattern: "(?~apple)", test: "banana", result: "match", options: "", description: "Matches 'banana' because 'apple' is absent." },
          { pattern: "(?~hello)", test: "world", result: "match", options: "", description: "Matches 'world' because 'hello' is absent." }
        ]
      },

      "Back-references" => {
        short: "GBkrf",
        description: "Match the same text as previously captured using back-references.",
        examples: [
          { pattern: "(\\d)\\1", test: "11", result: "match", options: "", description: "Matches '11' because both digits are the same." },
          { pattern: "(?<word>\\w+)\\s\\k<word>", test: "hello hello", result: "match", options: "", description: "Matches 'hello hello' using a named back-reference." },
          { pattern: "(\\d+)\\k<1>", test: "123123", result: "match", options: "", description: "Matches '123123' using a numbered back-reference." },
          { pattern: "(\\w+)\\s\\1", test: "hello hello", result: "match", options: "", description: "Matches 'hello hello' because both words are the same." },
          { pattern: "(\\d{3})-(\\d{2})-(\\d{4})\\k<1>", test: "123-45-6789123", result: "match", options: "", description: "Matches '123-45-6789123' using a nested back-reference to the first group." },
          { pattern: "(\\w+)-(\\w+)\\k<2>", test: "apple-orangeorange", result: "match", options: "", description: "Matches 'apple-orangeorange' where the second group repeats using \k<2>." },
          { pattern: "(\\d{3})-(\\d{2})-(\\d{4})\\k<2>", test: "123-45-678945", result: "match", options: "", description: "Matches '123-45-678945' using a numbered back-reference to group 2." },
          { pattern: "(\\d+)\\1", test: "12345", result: "no-match", options: "", description: "No match for '12345' because the digits don't repeat." },
          { pattern: "(\\w+)\\s\\k<3>", test: "hello hello", result: "no-match", options: "", description: "No match for 'hello hello' because there is no third capture group." }
        ]
      },

      "Capturing" => {
        short: "GCap",
        description: "Capture matched groups for later reference.",
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

      "Comments" => {
        short: "GCmt",
        description: "Include comments inside regular expressions using (?# comment ).",
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

      "Named" => {
        short: "GName",
        description: "Capture groups with a specific name for easier reference.",
        examples: [
          { pattern: "(?<name>abc)", test: "abc", result: "match", options: "", description: "Captures 'abc' in a group named 'name'." },
          { pattern: "(?'year'\\d{4})-(?'month'\\d{2})-(?'day'\\d{2})", test: "2023-07-25", result: "match", options: "", description: "Captures the year, month, and day into named groups." },
          { pattern: "(?<user>\\w+)@(?<domain>\\w+\\.\\w+)", test: "alice@example.com", result: "match", options: "", description: "Captures 'alice' in the named group 'alice' and 'example.com' in the named group 'domain'." },
          { pattern: "(?'hour'\\d{2}):(?'minute'\\d{2})", test: "14:30", result: "match", options: "", description: "Captures hour and minute into named groups." },
          { pattern: "(?<phone>\\+\\d{1,2} \\d{3}-\\d{4})", test: "+1 123-4567", result: "match", options: "", description: "Captures a phone number in the named group 'phone'." }
        ]
      },

      "Options" => {
        short: "GOpt",
        description: "Modify regex behavior using inline options like (?i), (?m), etc.",
        examples: [
          { pattern: "(?i)abc", test: "ABC", result: "match", options: "", description: "Matches 'ABC' case-insensitively due to the (?i) option." },
          { pattern: "(?m)^abc", test: "abc\nabc", result: "match", options: "", description: "Matches 'abc' at the start of each line due to the (?m) multiline option." },
          { pattern: "(?s).+", test: "Line 1\nLine 2", result: "match", options: "", description: "Matches the entire string including newlines because of the (?s) dotall option." },
          { pattern: "(?x) a # space is ignored\nb", test: "ab", result: "match", options: "", description: "Matches 'ab' while ignoring the space and comment due to the (?x) extended option." },
          { pattern: "(?i) hello(?-i)world", test: "HELLOworld", result: "match", options: "", description: "Matches 'HELLO' case-insensitively and 'world' case-sensitively due to inline options." },
          { pattern: "(?i)(abc)(?-i)def", test: "ABCdef", result: "match", options: "", description: "Matches 'ABC' case-insensitively and 'def' case-sensitively." },
          { pattern: "(?m)\\bstart\\b", test: "start\nstart", result: "match", options: "", description: "Matches 'start' at the beginning of each line due to the (?m) option." },
          { pattern: "(?x) a # space is ignored\nc", test: "ac", result: "match", options: "", description: "Matches 'ac' while ignoring the comment and spaces due to the (?x) option." }
        ]
      },

      "Passive" => {
        short: "GPsv",
        description: "Create a non-capturing group that doesn't store matches.",
        examples: [
          { pattern: "(?:abc)", test: "abc", result: "match", options: "", description: "Non-capturing group for 'abc'." },
          { pattern: "(?:\\d{2})-(?:\\d{2})-(?:\\d{4})", test: "12-34-5678", result: "match", options: "", description: "Non-capturing groups for the date pattern." },
          { pattern: "(?:\\w+)@(\\w+\\.\\w+)", test: "alice@example.com", result: "match", options: "", description: "Captures domain but ignores the username using passive group." }
        ]
      },

      "Subexp. Calls" => {
        short: "GSub",
        description: "Call a previously defined subexpression (either by name or index).",
        examples: [
          { pattern: "\\g<1>", test: "123", result: "match", options: "", description: "Refers to the first captured group." },
          { pattern: "\\g<name>", test: "hello", result: "match", options: "", description: "Refers to the group named 'name'." },
          { pattern: "\\g<1>\\g<2>", test: "123abc", result: "match", options: "", description: "Refers to two captured groups by index." }
        ]
      },

      "Keep" => {
        short: "Kp",
        description: "Keep the current match and resume matching after it using \\K.",
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
        short: "Lit",
        description: "Match specific literal characters including Unicode characters.",
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
        short: "POSIX",
        description: "Match POSIX character classes like [:alpha:], [:digit:], etc. Can also use negation (e.g., [:^alpha:]) to match non-characters.",
        examples: [
          { pattern: "[:alpha:]", test: "abc123!", result: "match", options: "", description: "Matches 'a', 'b', and 'c' because they are alphabetic characters." },
          { pattern: "[:alpha:]", test: "abc123!xyz", result: "match", options: "", description: "Matches 'a', 'b', 'c', 'x', 'y', 'z' because they are alphabetic characters." },
          { pattern: "[:alpha:]", test: "123!xyz", result: "no-match", options: "", description: "No match for digits and punctuation, only alphabetic characters match." },
          { pattern: "[:digit:]", test: "abc123!", result: "match", options: "", description: "Matches '1', '2', and '3' because they are digits." },
          { pattern: "[:alnum:]", test: "abc123!xyz", result: "match", options: "", description: "Matches 'a', 'b', 'c', '1', '2', '3', 'x', 'y', 'z' because they are alphanumeric characters." },
          { pattern: "[:space:]", test: "abc 123! xyz", result: "match", options: "", description: "Matches spaces because they are whitespace characters." },
          { pattern: "[:punct:]", test: "abc123!", result: "match", options: "", description: "Matches '!' because it's a punctuation character." },
          { pattern: "[:^alpha:]", test: "abc123!", result: "match", options: "", description: "Matches '1', '2', '3', '!' because they are not alphabetic characters." },
          { pattern: "[:^digit:]", test: "abc123!", result: "match", options: "", description: "Matches 'a', 'b', 'c', '!' because they are not digits." },
          { pattern: "[:^space:]", test: "abc 123! xyz", result: "match", options: "", description: "Matches 'a', 'b', 'c', '1', '2', '3', '!', 'x', 'y', 'z' because they are not spaces." }
       ]
      },

      "Quantifiers" => {
        short: "Qnt",
        description: "Define how many times a pattern should match using quantifiers like *, +, ?, {n,m}, {n,} etc.",
        examples: [
          { pattern: "a*", test: "abc123!", result: "match", options: "", description: "Matches zero or more 'a'. Matches '' (empty string) or 'a' at the start." },
          { pattern: "a*", test: "aaaabc123!", result: "match", options: "", description: "Matches 'aaa' because it's zero or more 'a's." },
          { pattern: "a+", test: "abc123!", result: "match", options: "", description: "Matches one or more 'a'. Matches the first 'a'." },
          { pattern: "a{2}", test: "abc123!", result: "no-match", options: "", description: "No match because there is only one 'a', but 'a{2}' requires two occurrences." },
          { pattern: "(abc)*", test: "abc123!", result: "match", options: "", description: "Matches zero or more 'abc'. Matches 'abc' once at the beginning." },
          { pattern: "(abc)+", test: "abc123!", result: "match", options: "", description: "Matches one or more 'abc'. Matches 'abc' at the start." },
          { pattern: "(abc)?", test: "abc123!", result: "match", options: "", description: "Matches zero or one 'abc'. Matches 'abc' at the start." },
          { pattern: "(abc){2}", test: "abcabc123!", result: "match", options: "", description: "Matches 'abcabc' because there are exactly two occurrences of 'abc'." },
          { pattern: "(abc){2,3}", test: "abcabc123!", result: "match", options: "", description: "Matches 'abcabc' because there are exactly two occurrences of 'abc'." },
          { pattern: "(abc){2,3}", test: "abcabcabc123!", result: "match", options: "", description: "Matches 'abcabcabc' because there are exactly three occurrences of 'abc'." }
        ]
      },

      "String Escapes" => {
        short: "StrEsc",
        description: "Match special characters using escape sequences like \d, \w, \s, etc.",
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

      "Unicode Properties": {
        short: "Uni",
        description: "Match Unicode characters based on properties like script, block, or category.",
        examples: [
          { pattern: "\\p{Script=Hiragana}", test: "こんにちは", result: "match", options: "", description: "Matches 'こんにちは' because it is written in Hiragana." },
          { pattern: "\\p{Age=5.2}", test: "U+1F60D", result: "match", options: "", description: "Matches emoji with Unicode age 5.2." },
          { pattern: "\\p{InGreek}", test: "π", result: "match", options: "", description: "Matches Greek letter 'π'." },
          { pattern: "\\p{Alpha}", test: "abc123", result: "match", options: "", description: "Matches 'a', 'b', 'c' because they are alphabetic characters." },
          { pattern: "\\P{Script=Latin}", test: "こんにちは", result: "match", options: "", description: "Matches because 'こんにちは' is not in the Latin script." },
          { pattern: "\\p{Block=Basic_Latin}", test: "abc", result: "match", options: "", description: "Matches 'abc' because they are in the Basic Latin block." },
          { pattern: "\\p{General_Category=Letter}", test: "a", result: "match", options: "", description: "Matches letter 'a' because it's categorized as a letter." },
          { pattern: "\\p{Uppercase_Letter}", test: "A", result: "match", options: "", description: "Matches uppercase 'A'." },
          { pattern: "\\p{Lowercase_Letter}", test: "z", result: "match", options: "", description: "Matches lowercase 'z'." },
          { pattern: "\\p{Math}", test: "∑", result: "match", options: "", description: "Matches '∑' (summation symbol), a mathematical symbol." },
          { pattern: '\\p{Emoji}', test: "👨‍👩‍👧‍👦", result: "match", options: "", description: "Matches the family emoji 👨‍👩‍👧‍👦 (family: man, woman, girl, boy)" }
         ]
      }
    }
  end
end
