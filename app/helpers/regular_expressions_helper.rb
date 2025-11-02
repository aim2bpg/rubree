module RegularExpressionsHelper
  def regex_reference_sections
    orig = [
      {
        title: "Character Classes & Anchors",
        col_class: "grid-cols-[80px_1fr]",
        items: [
          ["[abc]", nil],
          ["[^abc]", nil],
          ["[a-z]", nil],
          ["[a-zA-Z]", nil],
          ["^", nil],
          ["$", nil],
          ['\\A', nil],
          ['\\z', nil]
        ]
      },
      {
        title: "Common Patterns",
        col_class: "grid-cols-[30px_1fr]",
        items: [
          [".", nil],
          ['\\s', nil],
          ['\\S', nil],
          ['\\d', nil],
          ['\\D', nil],
          ['\\w', nil],
          ['\\W', nil],
          ['\\b', nil]
        ]
      },
      {
        title: "Groups & Quantifiers",
        col_class: "grid-cols-[60px_1fr]",
        items: [
          ["(...)", nil],
          ["(a|b)", nil],
          ["a?", nil],
          ["a*", nil],
          ["a+", nil],
          ["a{3}", nil],
          ["a{3,}", nil],
          ["a{3,6}", nil]
        ]
      }
    ]

    # translate titles/items when translations are present; fallback to original
    orig.map.with_index do |sec, s_idx|
      key = sec[:title].parameterize
      translated_title = I18n.t("regular_expressions.reference.sections.#{key}.title")
      translated_items = sec[:items].map.with_index do |(pattern, desc), i|
        [pattern, I18n.t("regular_expressions.reference.sections.#{key}.items.#{i}")]
      end

      sec.merge(title: translated_title, items: translated_items)
    end
  end

  def regex_reference_options
    orig = [
      ["i", nil],
      ["m", nil],
      ["x", nil]
    ]

    orig.map do |flag, desc|
      # translations for options live under reference.sections.options in locale files
      [flag, I18n.t("regular_expressions.reference.sections.options.#{flag}")]
    end
  end

  def regexp_example_categories
      orig = {
        "Basic operations" => {
          short: nil,
          description: nil,
          examples: [

            # --- Concatenation ---
            { pattern: "abc", test: "abc", result: "match", options: "", substitution: "", description: nil },
            { pattern: "ab", test: "cab", result: "match", options: "", substitution: "", description: nil },
            { pattern: "ab", test: "acb", result: "no match", options: "", substitution: "", description: nil },

            # --- Alternation ---
            { pattern: "a|b|c", test: "abc", result: "match", options: "", substitution: "", description: nil },
            { pattern: "a|b*", test: "bbb", result: "match", options: "", substitution: "", description: nil },
            { pattern: "a|b*", test: "aaa", result: "match", options: "", substitution: "", description: nil },

            # --- Repeat ---
            { pattern: "a*", test: "a", result: "match", options: "", substitution: "", description: nil },
            { pattern: "a*", test: "aaa", result: "match", options: "", substitution: "", description: nil },
            { pattern: "a*", test: "bbb", result: "match", options: "", substitution: "", description: nil },

            # --- Combination ---
            { pattern: "ab|cd", test: "cd", result: "match", options: "", substitution: "", description: nil },
            { pattern: "a|b*", test: "a", result: "match", options: "", substitution: "", description: nil },
            { pattern: "a*bc", test: "aaabc", result: "match", options: "", substitution: "", description: nil }
          ]
        },

        "Syntax sugar" => {
          short: nil,
          description: nil,
          examples: [

            # --- Quantifiers ---
            { pattern: "a+", test: "aaab", result: "match", options: "", substitution: "", description: nil },
            { pattern: "a?", test: "apple", result: "match", options: "", substitution: "", description: nil },
            { pattern: "a{2,4}", test: "aaabc", result: "match", options: "", substitution: "", description: nil },

            # --- Dot ---
            { pattern: "a.c", test: "abc", result: "match", options: "", substitution: "", description: nil },

            # --- Character classes ---
            { pattern: "[a-z]", test: "g", result: "match", options: "", substitution: "", description: nil },
            { pattern: "[a-z-]", test: "-", result: "match", options: "", substitution: "", description: nil },
            { pattern: "[^a-z]", test: "A", result: "match", options: "", substitution: "", description: nil },

            # --- Escape sequences ---
            { pattern: "a\\tb", test: "a\tb", result: "match", options: "", substitution: "", description: nil },

            # --- Anchors ---
            { pattern: "^a", test: "abc", result: "match", options: "", substitution: "", description: nil },
            { pattern: "c$", test: "abc", result: "match", options: "", substitution: "", description: nil },
            { pattern: "\\bword\\b", test: " word ", result: "match", options: "", substitution: "", description: nil },
            { pattern: "\\Bend", test: "bend", result: "match", options: "", substitution: "", description: nil }
          ]
        },

        "Pattern Matching Examples" => {
          short: nil,
          description: nil,
          examples: [
            # Email address with local and domain parts
            { pattern: "^(?<local_part>[a-zA-Z0-9.!#$%&'*+\\/=?^_`{|}~-]+)@(?<domain_name>([a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)(?:\\.(?:[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?))*)$", test: "test@example.com\nfoo.bar@sub.domain.org\nbad@.com\nuser@site.co.jp\nwrong@site,com", result: "match", options: "m", substitution: "", description: nil },

            # URL capturing scheme, host, path, query and fragment
            { pattern: "^(?<scheme>https?|ftp):\\/\\/(?<host>[a-zA-Z0-9.-]+)(?<path>\\/[^\\s?#]*)?(\\?(?<query>[^#\\s]*))?(#(?<fragment>\\S+))?$", test: "https://example.com\nhttps://example.com/path?arg=1\nftp://files.net/path#section\nhttp://localhost\ninvalid_url", result: "match", options: "m", substitution: "", description: nil },

            # IPv4 address capturing each octet fully named
            { pattern: "^(?<octet1>25[0-5]|2[0-4]\\d|1\\d\\d|[1-9]?\\d)\\.(?<octet2>25[0-5]|2[0-4]\\d|1\\d\\d|[1-9]?\\d)\\.(?<octet3>25[0-5]|2[0-4]\\d|1\\d\\d|[1-9]?\\d)\\.(?<octet4>25[0-5]|2[0-4]\\d|1\\d\\d|[1-9]?\\d)$", test: "192.168.0.1\n255.255.255.255\n256.100.100.100\n10.0.0.1\n0.0.0.0", result: "match", options: "m", substitution: "", description: nil },

            # IPv6 address capturing each 16-bit block with full names (also supports shorthand notation)
            { pattern: "^(?<block1>[0-9a-fA-F]{1,4}):(?<block2>[0-9a-fA-F]{1,4}):(?<block3>[0-9a-fA-F]{1,4}):(?<block4>[0-9a-fA-F]{1,4}):(?<block5>[0-9a-fA-F]{1,4}):(?<block6>[0-9a-fA-F]{1,4}):(?<block7>[0-9a-fA-F]{1,4}):(?<block8>[0-9a-fA-F]{1,4})$|^(?<compressed_address>([0-9a-fA-F]{1,4}:){1,7}:)$", test: "2001:0db8:85a3:0000:0000:8a2e:0370:7334\n2001:db8::8a2e:370:7334\n::1\ninvalid::ip\nfe80::1ff:fe23:4567:890a", result: "match", options: "m", substitution: "", description: nil },

            # Extract ERROR log entries with timestamp, level and non-greedy message
            { pattern: "^\\[(?<timestamp>\\d{4}-\\d{2}-\\d{2} \\d{2}:\\d{2}:\\d{2})\\] \\[(?<level>ERROR)\\] (?<message>.+?)$", test: "[2025-08-17 12:00:00] [INFO] Start\n[2025-08-17 12:01:00] [ERROR] Failed\n[2025-08-17 12:02:00] [WARN] Low\n[2025-08-17 12:03:00] [ERROR] Crash\n[2025-08-17 12:04:00] [INFO] Done", result: "match", options: "m", substitution: "", description: nil },

            # YAML key-value pair with key and single-line value capture
            { pattern: "^(?<parent>[a-zA-Z0-9_-]+):\\n(?: {2}(?<key1>[a-zA-Z0-9_-]+): (?<value1>.+)\\n){3}\\s*(?: {2}(?<key2>[a-zA-Z0-9_-]+): (?<value2>.+)\\n){3}?", test: "parent1:\n  name: Alice\n  age: 30\n  city: Tokyo\nparent2:\n  hobby: hiking\n  pet: dog\n  food: sushi\ninvalid line", result: "match", options: "m", substitution: "", description: nil }
          ]
        },

        "Alternations" => {
          short: nil,
          description: nil,
          examples: [
            { pattern: "cat|dog", test: "I have a cat", result: "match", options: "", substitution: "", description: nil },
            { pattern: "cat|dog", test: "I have a dog", result: "match", options: "", substitution: "", description: nil },
            { pattern: "cat|dog", test: "I have a bird", result: "no-match", options: "", substitution: "", description: nil },
            { pattern: "red|green|blue", test: "green apple", result: "match", options: "", substitution: "", description: nil },
            { pattern: "red|green|blue", test: "yellow banana", result: "no-match", options: "", substitution: "", description: nil }
          ]
        },

        "Anchors" => {
          short: nil,
          description: nil,
          examples: [
            { pattern: "^start", test: "start here", result: "match", options: "", substitution: "", description: nil },
            { pattern: "^start", test: "this is start", result: "no-match", options: "", substitution: "", description: nil },
            { pattern: "end$", test: "This is the end", result: "match", options: "", substitution: "", description: nil },
            { pattern: "end$", test: "end somewhere", result: "no-match", options: "", substitution: "", description: nil },
            { pattern: "\\bword\\b", test: "The word is here", result: "match", options: "", substitution: "", description: nil },
            { pattern: "\\bhello\\b", test: "helloworld", result: "no-match", options: "", substitution: "", description: nil },
            { pattern: "\\Aabc", test: "abc anywhere", result: "match", options: "", substitution: "", description: nil },
            { pattern: "\\Aabc", test: "this abc anywhere", result: "no-match", options: "", substitution: "", description: nil },
            { pattern: "xyz\\b", test: "xyzxyz", result: "match", options: "", substitution: "", description: nil },
            { pattern: "xyz\\b", test: "xyz is here", result: "match", options: "", substitution: "", description: nil },
            { pattern: "start\\Z", test: "start", result: "match", options: "", substitution: "", description: nil },
            { pattern: "start\\Z", test: "test start", result: "match", options: "", substitution: "", description: nil }
          ]
        },

        "Character Classes" => {
          short: nil,
          description: nil,
          examples: [
            { pattern: "[abc]", test: "a1bc", result: "match", options: "", substitution: "", description: nil },
            { pattern: "[^abc]", test: "a1bc", result: "match", options: "", substitution: "", description: nil },
            { pattern: "[0-9]", test: "abc123", result: "match", options: "", substitution: "", description: nil },
            { pattern: "[a-z]", test: "abc123", result: "match", options: "", substitution: "", description: nil },
            { pattern: "[A-Z]", test: "abc123XYZ", result: "match", options: "", substitution: "", description: nil },
            { pattern: "[^\\]", test: "hello\\world", result: "match", options: "", substitution: "", description: nil },
            { pattern: "[a-d&&aeiou]", test: "abcd123", result: "match", options: "", substitution: "", description: nil },
            { pattern: "[a-d&&[^aeiou]]", test: "abcd123", result: "match", options: "", substitution: "", description: nil },
            { pattern: "[a=e=b]", test: "a", result: "match", options: "", substitution: "", description: nil }
          ]
        },

        "Character Types" => {
          short: nil,
          description: nil,
          examples: [
            { pattern: "\\d", test: "hello123", result: "match", options: "", substitution: "", description: nil },
            { pattern: "\\d", test: "helloworld", result: "no-match", options: "", substitution: "", description: nil },
            { pattern: "\\H", test: "hello world", result: "match", options: "", substitution: "", description: nil },
            { pattern: "\\s", test: "hello world", result: "match", options: "", substitution: "", description: nil },
            { pattern: "\\S", test: "hello world", result: "match", options: "", substitution: "", description: nil },
            { pattern: "\\w", test: "helloworld123", result: "match", options: "", substitution: "", description: nil },
            { pattern: "\\w", test: "hello@world", result: "match", options: "", substitution: "", description: nil },
            { pattern: "\\W", test: "hello@world", result: "match", options: "", substitution: "", description: nil },
            { pattern: "\\W", test: "helloworld", result: "no-match", options: "", substitution: "", description: nil }
          ]
        },

        "Cluster Types" => {
          short: nil,
          description: nil,
          examples: [
            { pattern: "\\R", test: "abc\n123", result: "match", options: "", substitution: "", description: nil },
            { pattern: "\\R", test: "hello\rworld", result: "match", options: "", substitution: "", description: nil },
            { pattern: "\\X", test: "👋", result: "match", options: "", substitution: "", description: nil },
            { pattern: "\\X", test: "abc👋123", result: "match", options: "", substitution: "", description: nil },
            { pattern: "\\X", test: "abc\u0301", result: "match", options: "", substitution: "", description: nil }
          ]
        },

        "Conditional Expressions" => {
          short: nil,
          description: nil,
          examples: [
            { pattern: "(?<A>a)(?(<A>)T|F)", test: "aT", result: "match", options: "", substitution: "", description: nil },
            { pattern: "(?<A>a)(?(<A>)T|)", test: "aT", result: "match", options: "", substitution: "", description: nil },
            { pattern: "(a)(?(001)T)", test: "aT", result: "match", options: "", substitution: "", description: nil },
            { pattern: "\\A(?:(set)|(print))\\s+(\\w+)(?(1)=(\\d+))\\z", test: "set x=32", result: "match", options: "", substitution: "", description: nil },
            { pattern: "\\A(?:(set)|(print))\\s+(\\w+)(?(1)=(\\d+))\\z", test: "print x", result: "match", options: "", substitution: "", description: nil },
            { pattern: "\\A(?:(set)|(print))\\s+(\\w+)(?(1)=(\\d+))\\z", test: "set y", result: "no-match", options: "", substitution: "", description: nil }
          ]
        },

        "Escape Sequences" => {
          short: nil,
          description: nil,
          examples: [
            { pattern: "\\t", test: "a\t", result: "match", options: "", substitution: "", description: nil },
            { pattern: "\\n", test: "a\n", result: "match", options: "", substitution: "", description: nil },
            { pattern: "\\d", test: "5", result: "match", options: "", substitution: "", description: nil },
            { pattern: "\\d", test: "a", result: "no-match", options: "", substitution: "", description: nil },
            { pattern: "\\s", test: "a ", result: "match", options: "", substitution: "", description: nil },
            { pattern: "\\S", test: "a", result: "match", options: "", substitution: "", description: nil },
            { pattern: "\\w", test: "a", result: "match", options: "", substitution: "", description: nil },
            { pattern: "\\W", test: "$", result: "match", options: "", substitution: "", description: nil },
            { pattern: "\\b", test: "word", result: "match", options: "", substitution: "", description: nil },
            { pattern: "\\B", test: "word", result: "no-match", options: "", substitution: "", description: nil },
            { pattern: "\\f", test: "a\f", result: "match", options: "", substitution: "", description: nil },
            { pattern: "\\r", test: "a\\r", result: "match", options: "", substitution: "", description: nil },
            { pattern: "\\0", test: "a\0", result: "match", options: "", substitution: "", description: nil },
            { pattern: "\\x41", test: "A", result: "match", options: "", substitution: "", description: nil },
            { pattern: "\\\\+", test: "a\\", result: "match", options: "", substitution: "", description: nil },
            { pattern: "\\?", test: "?", result: "match", options: "", substitution: "", description: nil }
          ]
        },

        "Free Space" => {
          short: nil,
          description: nil,
          examples: [
            { pattern: "a  # comment \nb", test: "ab", result: "match", options: "x", substitution: "", description: nil },
            { pattern: "  a  # word\n  b", test: "ab", result: "match", options: "x", substitution: "", description: nil },
            { pattern: "  a #word \nb", test: "ab", result: "match", options: "x", substitution: "", description: nil },
            { pattern: "   a   # starting\n   b", test: "ab", result: "match", options: "x", substitution: "", description: nil }
          ]
        },

        "Group Assertions" => {
          short: nil,
          description: nil,
          examples: [
            { pattern: "(?=abc)", test: "abc", result: "match", options: "", substitution: "", description: nil },
            { pattern: "(?=\\w+)", test: "hello world", result: "match", options: "", substitution: "", description: nil },
            { pattern: "(?!abc)", test: "xyz", result: "match", options: "", substitution: "", description: nil },
            { pattern: "(?<=abc)", test: "abcxyz", result: "match", options: "", substitution: "", description: nil },
            { pattern: "(?<=\\d{3})", test: "123abc", result: "match", options: "", substitution: "", description: nil },
            { pattern: "(?<=\\b)", test: "hello", result: "match", options: "", substitution: "", description: nil },
            { pattern: "(?<!abc)", test: "xyzabc", result: "match", options: "", substitution: "", description: nil },
            { pattern: "(?<!\\d)", test: "abc123", result: "match", options: "", substitution: "", description: nil },
            { pattern: "(?<!\\d{2})", test: "abc123", result: "match", options: "", substitution: "", description: nil }
          ]
        },

        "Group Atomic" => {
          short: nil,
          description: nil,
          examples: [
            { pattern: "a(bc|b)c", test: "abc", result: "match", options: "", substitution: "", description: nil },
            { pattern: "a(?>bc|b)c", test: "abc", result: "no-match", options: "", substitution: "", description: nil },
            { pattern: "(\\w+)\\d{3}", test: "user123", result: "match", options: "", substitution: "", description: nil },
            { pattern: "(?>\\w+)\\d{3}", test: "user123", result: "no-match", options: "", substitution: "", description: nil },
            { pattern: "Start(A+|A*B)End", test: "StartABEnd", result: "match", options: "", substitution: "", description: nil },
            { pattern: "Start(?>A+|A*B)End", test: "StartABEnd", result: "no-match", options: "", substitution: "", description: nil }
          ]
        },

        "Group Absence" => {
          short: nil,
          description: nil,
          examples: [
            { pattern: "(?~abc)", test: "ab", result: "match", options: "", substitution: "", description: nil },
            { pattern: "(?~abc)", test: "aab", result: "match", options: "", substitution: "", description: nil },
            { pattern: "(?~abc)", test: "abb", result: "match", options: "", substitution: "", description: nil },
            { pattern: "(?~abc)", test: "abc", result: "match", options: "", substitution: "", description: nil },
            { pattern: "^(?~abc)$", test: "abc", result: "no-match", options: "", substitution: "", description: nil },
            { pattern: "(?~abc)", test: "aabc", result: "match", options: "", substitution: "", description: nil },
            { pattern: "(?~abc)", test: "ccabcdd", result: "match", options: "", substitution: "", description: nil },
            { pattern: "/\\*(?~\\*/)*\\*/", test: "/**/", result: "match", options: "", substitution: "", description: nil },
            { pattern: "/\\*(?~\\*/)*\\*/", test: "/* foo bar */", result: "match", options: "", substitution: "", description: nil }
          ]
        },

        "Group Back-references" => {
          short: nil,
          description: nil,
          examples: [
            { pattern: "(\\d)\\1", test: "11", result: "match", options: "", substitution: "", description: nil },
            { pattern: "(?<word>\\w+)\\s\\k<word>", test: "hello hello", result: "match", options: "", substitution: "", description: nil },
            { pattern: "(\\d+)\\k<1>", test: "123123", result: "match", options: "", substitution: "", description: nil },
            { pattern: "(\\w+)\\s\\1", test: "hello hello", result: "match", options: "", substitution: "", description: nil },
            { pattern: "(\\d{3})-(\\d{2})-(\\d{4})\\k<1>", test: "123-45-6789123", result: "match", options: "", substitution: "", description: nil },
            { pattern: "(\\w+)-(\\w+)\\k<2>", test: "apple-orangeorange", result: "match", options: "", substitution: "", description: nil },
            { pattern: "(\\d{3})-(\\d{2})-(\\d{4})\\k<2>", test: "123-45-678945", result: "match", options: "", substitution: "", description: nil },
            { pattern: "(\\d+)\\1", test: "12345", result: "no-match", options: "", substitution: "", description: nil },
            { pattern: "(.)(.)\\k<-2>\\k<-1>", test: "xyzyz", result: "match", options: "", substitution: "", description: nil }
          ]
        },

        "Group Capturing" => {
          short: nil,
          description: nil,
          examples: [
            { pattern: "(abc)", test: "abc", result: "match", options: "", substitution: "", description: nil },
            { pattern: "(\\d{2})-(\\d{2})-(\\d{4})", test: "12-34-5678", result: "match", options: "", substitution: "", description: nil },
            { pattern: "(\\w+)@(\\w+\\.\\w+)", test: "alice@example.com", result: "match", options: "", substitution: "", description: nil },
            { pattern: "(\\d+)-(\\d+)", test: "123-456", result: "match", options: "", substitution: "", description: nil },
            { pattern: "(\\w{3})-(\\w{3})", test: "abc-def", result: "match", options: "", substitution: "", description: nil },
            { pattern: "(\\d{4})(\\d{2})(\\d{2})", test: "20211225", result: "match", options: "", substitution: "", description: nil },
            { pattern: "(\\w+)\\s(\\w+)", test: "hello world", result: "match", options: "", substitution: "", description: nil },
            { pattern: "(\\w+)\\s+\\1", test: "hello hello", result: "match", options: "", substitution: "", description: nil }
          ]
        },

        "Group Comments" => {
          short: nil,
          description: nil,
          examples: [
            { pattern: "(?# This is a comment)abc", test: "abc", result: "match", options: "", substitution: "", description: nil },
            { pattern: "a(?# matches 'a')b", test: "ab", result: "match", options: "", substitution: "", description: nil },
            { pattern: "(?#Start of string)^abc(?#End of string)$", test: "abc", result: "match", options: "", substitution: "", description: nil },
            { pattern: "(?# a comment in the middle )ab(?# another comment)", test: "ab", result: "match", options: "", substitution: "", description: nil },
            { pattern: "(?# This pattern matches digits )\\d+", test: "12345", result: "match", options: "", substitution: "", description: nil },
            { pattern: "(?# matches a space )\\s", test: " ", result: "match", options: "", substitution: "", description: nil },
            { pattern: "(?# comment before and after )\\w{3,}", test: "word", result: "match", options: "", substitution: "", description: nil }
          ]
        },

        "Group Named" => {
          short: nil,
          description: nil,
          examples: [
            { pattern: "(?<name>Alice)", test: "Alice", result: "match", options: "", substitution: "", description: nil },
            { pattern: "(?'name'Alice)", test: "Alice", result: "match", options: "", substitution: "", description: nil },
            { pattern: "(?P<name>Alice)", test: "Alice", result: "no-match", options: "", substitution: "", description: nil },
            { pattern: "(?<year>\\d{4})-(?'month'\\d{2})-(?'day'\\d{2})", test: "2023-07-25", result: "match", options: "", substitution: "", description: nil },
            { pattern: "(?<hour>\\d{2}):(?'minute'\\d{2})", test: "14:30", result: "match", options: "", substitution: "", description: nil },
            { pattern: "(?<user>\\w+)@(?<domain>\\w+\\.\\w+)", test: "alice@example.com", result: "match", options: "", substitution: "", description: nil },
            { pattern: "\\$(?<dollars>\\d+)\\.(?<cents>\\d+)", test: "$3.67", result: "match", options: "", substitution: "", description: nil },
            { pattern: "(?<vowel>[aeiou]).\\k<vowel>.\\k<vowel>", test: "ototomy", result: "match", options: "", substitution: "", description: nil },
            { pattern: "(?<name>\\w+)(\\d{3})", test: "user123", result: "match", options: "", substitution: "", description: nil }
          ]
        },

        "Group Options" => {
          short: nil,
          description: nil,
          examples: [
            { pattern: "(?i)abc", test: "ABC", result: "match", options: "", substitution: "", description: nil },
            { pattern: "(?m)^abc", test: "abc\nabc", result: "match", options: "", substitution: "", description: nil },
            { pattern: "(?x) a # space is ignored\nb", test: "ab", result: "match", options: "", substitution: "", description: nil },
            { pattern: "(?i)hello(?-i)world", test: "HELLOworld", result: "match", options: "", substitution: "", description: nil },
            { pattern: "(?i)(abc)(?-i)def", test: "ABCdef", result: "match", options: "", substitution: "", description: nil },
            { pattern: "(?m)\\bstart\\b", test: "start\nstart", result: "match", options: "", substitution: "", description: nil },
            { pattern: "(?x) a # space is ignored\nc", test: "ac", result: "match", options: "", substitution: "", description: nil }
          ]
        },

        "Group Passive" => {
          short: nil,
          description: nil,
          examples: [
            { pattern: "(?:abc)", test: "abc", result: "match", options: "", substitution: "", description: nil },
            { pattern: "(?:\\d{2})-(?:\\d{2})-(?:\\d{4})", test: "12-34-5678", result: "match", options: "", substitution: "", description: nil },
            { pattern: "(?:\\w+)@(\\w+\\.\\w+)", test: "alice@example.com", result: "match", options: "", substitution: "", description: nil }
          ]
        },

        "Group Subexpression Calls" => {
          short: nil,
          description: nil,
          examples: [
            { pattern: "(abc)\\g<1>", test: "abcabc", result: "match", options: "", substitution: "", description: nil },
            { pattern: "(?<name>hello)\\g<name>", test: "hellohello", result: "match", options: "", substitution: "", description: nil },
            { pattern: "(abc)(def)\\g<1>\\g<2>", test: "abcdefabcdef", result: "match", options: "", substitution: "", description: nil }
          ]
        },

        "Keep" => {
          short: nil,
          description: nil,
          examples: [
            { pattern: "ab\\Kcd", test: "abcdef", result: "match", options: "", substitution: "", description: nil },
            { pattern: "a\\Kb", test: "abc", result: "match", options: "", substitution: "", description: nil },
            { pattern: "foo\\Kbar", test: "foobar", result: "match", options: "", substitution: "", description: nil },
            { pattern: "xyz\\Kabc", test: "xyzabc", result: "match", options: "", substitution: "", description: nil },
            { pattern: "start\\Kend", test: "startend", result: "match", options: "", substitution: "", description: nil },
            { pattern: "one\\Ktwo", test: "one two", result: "match", options: "", substitution: "", description: nil },
            { pattern: "aaa\\Kbbb", test: "aaabbb", result: "match", options: "", substitution: "", description: nil },
            { pattern: "1\\K2", test: "12", result: "match", options: "", substitution: "", description: nil },
            { pattern: "abc\\Kxyz", test: "abcxyz", result: "match", options: "", substitution: "", description: nil },
            { pattern: "quick\\Kbrown", test: "quickbrown", result: "match", options: "", substitution: "", description: nil }
          ]
        },

        "Literals" => {
          short: nil,
          description: nil,
          examples: [
            { pattern: "Ruby", test: "Ruby", result: "match", options: "", substitution: "", description: nil },
            { pattern: "apple", test: "apple pie", result: "match", options: "", substitution: "", description: nil },
            { pattern: "dog", test: "doghouse", result: "match", options: "", substitution: "", description: nil },
            { pattern: "123", test: "1234", result: "match", options: "", substitution: "", description: nil },
            { pattern: "abc", test: "abcdef", result: "match", options: "", substitution: "", description: nil },
            { pattern: "😃", test: "I am happy 😃", result: "match", options: "", substitution: "", description: nil },
            { pattern: "ルビー", test: "私はルビーが好きです", result: "match", options: "", substitution: "", description: nil },
            { pattern: "روبي", test: "اسمي روبي", result: "match", options: "", substitution: "", description: nil },
            { pattern: "apple", test: "applepie", result: "no-match", options: "", substitution: "", description: nil },
            { pattern: "dog", test: "god", result: "no-match", options: "", substitution: "", description: nil },
            { pattern: "🌍", test: "world 🌍", result: "match", options: "", substitution: "", description: nil }
          ]
        },

        "POSIX Classes" => {
          short: nil,
          description: nil,
          examples: [
            # --- Alphabetic Characters ---
            { pattern: "[[:alpha:]]+", test: "abc123XYZ", result: "match", options: "", substitution: "", description: nil },
            { pattern: "[[:^alpha:]]+", test: "abc123XYZ", result: "match", options: "", substitution: "", description: nil },

            # --- Digit Characters ---
            { pattern: "[[:digit:]]+", test: "abc123.45def", result: "match", options: "", substitution: "", description: nil },

            # --- Punctuation Characters ---
            { pattern: "[[:punct:]]+", test: "hello!?", result: "match", options: "", substitution: "", description: nil },

            # --- Whitespace Characters ---
            { pattern: "[[:space:]]+", test: "a b\tc\n", result: "match", options: "", substitution: "", description: nil },

            # --- Case Sensitivity ---
            { pattern: "[[:lower:]]+", test: "AbC", result: "match", options: "", substitution: "", description: nil },
            { pattern: "[[:upper:]]+", test: "AbC", result: "match", options: "", substitution: "", description: nil }
          ]
        },

        "Quantifiers Greedy" => {
          short: nil,
          description: nil,
          examples: [
            { pattern: "a*", test: "abc123!", result: "match", options: "", substitution: "", description: nil },
            { pattern: "a*", test: "aaaabc123!", result: "match", options: "", substitution: "", description: nil },
            { pattern: "a+", test: "abc123!", result: "match", options: "", substitution: "", description: nil },
            { pattern: "a{2}", test: "abc123!", result: "no-match", options: "", substitution: "", description: nil },
            { pattern: "(abc)*", test: "abc123!", result: "match", options: "", substitution: "", description: nil },
            { pattern: "(abc)+", test: "abc123!", result: "match", options: "", substitution: "", description: nil },
            { pattern: "(abc)?", test: "abc123!", result: "match", options: "", substitution: "", description: nil },
            { pattern: "(abc){2}", test: "abcabc123!", result: "match", options: "", substitution: "", description: nil },
            { pattern: "(abc){2,3}", test: "abcabc123!", result: "match", options: "", substitution: "", description: nil },
            { pattern: "(abc){2,3}", test: "abcabcabc123!", result: "match", options: "", substitution: "", description: nil }
          ]
        },

        "Quantifiers Reluctant (Lazy)" => {
          short: nil,
          description: nil,
          examples: [
            { pattern: "a*?", test: "abc123!", result: "match", options: "", substitution: "", description: nil },
            { pattern: "a*?", test: "aaaabc123!", result: "match", options: "", substitution: "", description: nil },
            { pattern: "a+?", test: "abc123!", result: "match", options: "", substitution: "", description: nil },
            { pattern: "a{2}?", test: "abc123!", result: "no-match", options: "", substitution: "", description: nil },
            { pattern: "(abc)*?", test: "abc123!", result: "match", options: "", substitution: "", description: nil },
            { pattern: "(abc)+?", test: "abc123!", result: "match", options: "", substitution: "", description: nil },
            { pattern: "(abc)?", test: "abc123!", result: "match", options: "", substitution: "", description: nil },
            { pattern: "(abc){2}?", test: "abcabc123!", result: "match", options: "", substitution: "", description: nil },
            { pattern: "(abc){2,3}?", test: "abcabc123!", result: "match", options: "", substitution: "", description: nil },
            { pattern: "(abc){2,3}?", test: "abcabcabc123!", result: "match", options: "", substitution: "", description: nil }
          ]
        },

        "Quantifiers Possessive" => {
          short: nil,
          description: nil,
          examples: [
            { pattern: "a*+", test: "abc123!", result: "match", options: "", substitution: "", description: nil },
            { pattern: "a*+", test: "aaaabc123!", result: "match", options: "", substitution: "", description: nil },
            { pattern: "a++", test: "abc123!", result: "match", options: "", substitution: "", description: nil },
            { pattern: "(abc)*+", test: "abc123!", result: "match", options: "", substitution: "", description: nil },
            { pattern: "(abc)++", test: "abc123!", result: "match", options: "", substitution: "", description: nil },
            { pattern: "(abc)?+", test: "abc123!", result: "match", options: "", substitution: "", description: nil }
          ]
        },

        "String Escapes" => {
          short: nil,
          description: nil,
          examples: [
            { pattern: "\\d", test: "123abc", result: "match", options: "", substitution: "", description: nil },
            { pattern: "\\d", test: "abc123", result: "no-match", options: "", substitution: "", description: nil },
            { pattern: "\\w", test: "abc123", result: "match", options: "", substitution: "", description: nil },
            { pattern: "\\w", test: "123!@#", result: "match", options: "", substitution: "", description: nil },
            { pattern: "\\W", test: "!@#", result: "match", options: "", substitution: "", description: nil },
            { pattern: "\\s", test: "abc def", result: "match", options: "", substitution: "", description: nil },
            { pattern: "\\S", test: "abc def", result: "match", options: "", substitution: "", description: nil },
            { pattern: "\\b", test: "hello world", result: "match", options: "", substitution: "", description: nil },
            { pattern: "\\B", test: "abc123", result: "match", options: "", substitution: "", description: nil },
            { pattern: "\\x20", test: "abc 123", result: "match", options: "", substitution: "", description: nil },
            { pattern: "\\u{1F60D}", test: "I love emojis 😍", result: "match", options: "", substitution: "", description: nil }
          ]
        },

        "Unicode Age" => {
          short: nil,
          description: nil,
          examples: [
            { pattern: "\\p{Age=5.2}+", test: "🤩☆あ", result: "match", options: "", substitution: "", description: nil },
            { pattern: "\\P{Age=6.1}+", test: "Aあ🤔", result: "match", options: "", substitution: "", description: nil },
            { pattern: "\\p{Age=3.0}+", test: "¡¿D", result: "match", options: "", substitution: "", description: nil },
            { pattern: "\\P{Age=5.2}+", test: "ABC🤩", result: "match", options: "", substitution: "", description: nil },
            { pattern: "\\p{Age=7.0}+", test: "𝄞C", result: "match", options: "", substitution: "", description: nil },
            { pattern: "\\P{Age=8.0}+", test: "abc🧭", result: "match", options: "", substitution: "", description: nil }
          ]
        },

        "Unicode Blocks" => {
          short: nil,
          description: nil,
          examples: [
            { pattern: "\\p{InKatakana}+", test: "カタカナあA", result: "match", options: "", substitution: "", description: nil },
            { pattern: "\\p{InArmenian}+", test: "ԱԲԳՖabc", result: "match", options: "", substitution: "", description: nil },
            { pattern: "\\P{InThai}+", test: "Helloกส", result: "match", options: "", substitution: "", description: nil },
            { pattern: "\\p{^InKhmer}+", test: "xyzខ", result: "match", options: "", substitution: "", description: nil },
            { pattern: "\\p{InCyrillic}+", test: "ПриветX", result: "match", options: "", substitution: "", description: nil },
            { pattern: "\\P{InHebrew}+", test: "ABCשלום", result: "match", options: "", substitution: "", description: nil }
          ]
        },

        "Unicode Classes" => {
          short: nil,
          description: nil,
          examples: [
            { pattern: "\\p{Alpha}+", test: "Hi1!", result: "match", options: "", substitution: "", description: nil },
            { pattern: "\\P{Space}+", test: "Az BC", result: "match", options: "", substitution: "", description: nil },
            { pattern: "\\p{^Alnum}+", test: "abc-123?", result: "match", options: "", substitution: "", description: nil },
            { pattern: "\\p{Digit}+", test: "123a", result: "match", options: "", substitution: "", description: nil },
            { pattern: "\\P{Alpha}+", test: "123A", result: "match", options: "", substitution: "", description: nil },
            { pattern: "\\p{Space}+", test: "a b", result: "match", options: "", substitution: "", description: nil }
          ]
        },

        "Unicode Derived" => {
          short: nil,
          description: nil,
          examples: [
            { pattern: "\\p{Math}+", test: "+×= x", result: "match", options: "", substitution: "", description: nil },
            { pattern: "\\P{Lowercase}+", test: "ABCdef", result: "match", options: "", substitution: "", description: nil },
            { pattern: "\\p{^Cased}+", test: "123_a", result: "match", options: "", substitution: "", description: nil },
            { pattern: "\\p{Lowercase}+", test: "abcD", result: "match", options: "", substitution: "", description: nil },
            { pattern: "\\P{Math}+", test: "abc+=", result: "match", options: "", substitution: "", description: nil },
            { pattern: "\\p{Alphabetic}+", test: "ab1", result: "match", options: "", substitution: "", description: nil }
          ]
        },

        "Unicode General Categories" => {
          short: nil,
          description: nil,
          examples: [
            { pattern: "\\p{LU}+", test: "ABCd", result: "match", options: "", substitution: "", description: nil },
            { pattern: "\\p{lu}+", test: "ABCd", result: "match", options: "", substitution: "", description: nil },
            { pattern: "\\p{Uppercase Letter}+", test: "ABCd", result: "match", options: "", substitution: "", description: nil },
            { pattern: "\\p{Uppercase_Letter}+", test: "ABCd", result: "match", options: "", substitution: "", description: nil },
            { pattern: "\\p{UPPERCASE-LETTER}+", test: "ABCd", result: "match", options: "", substitution: "", description: nil },
            { pattern: "\\P{Lu}+", test: "ABCd", result: "match", options: "", substitution: "", description: nil },
            { pattern: "\\p{^sc}+", test: "123Λ", result: "match", options: "", substitution: "", description: nil },
            { pattern: "\\p{Cc}+", test: "\u0001A", result: "match", options: "", substitution: "", description: nil },
            { pattern: "\\p{Cf}+", test: "\u200DA", result: "match", options: "", substitution: "", description: nil }
          ]
        },

        "Unicode Scripts" => {
          short: nil,
          description: nil,
          examples: [
            { pattern: "\\p{Arabic}+", test: "سلامHello", result: "match", options: "", substitution: "", description: nil },
            { pattern: "\\P{Hiragana}+", test: "ABCあいう", result: "match", options: "", substitution: "", description: nil },
            { pattern: "\\p{^Greek}+", test: "ABCΩΔ", result: "match", options: "", substitution: "", description: nil },
            { pattern: "\\p{Katakana}+", test: "カタカナB", result: "match", options: "", substitution: "", description: nil },
            { pattern: "\\p{Cyrillic}+", test: "ПриветX", result: "match", options: "", substitution: "", description: nil },
            { pattern: "\\P{Devanagari}+", test: "Helloनमस्ते", result: "match", options: "", substitution: "", description: nil }
          ]
        },

        "Unicode Simple Props" => {
          short: nil,
          description: nil,
          examples: [
            { pattern: "\\p{Dash}+", test: "–‑—A", result: "match", options: "", substitution: "", description: nil },
            { pattern: "\\p{Extender}+", test: "ːX", result: "match", options: "", substitution: "", description: nil },
            { pattern: "\\p{^Hyphen}+", test: "word-word", result: "match", options: "", substitution: "", description: nil },
            { pattern: "\\P{Dash}+", test: "ABC–", result: "match", options: "", substitution: "", description: nil },
            { pattern: "\\p{Hyphen}+", test: "-B", result: "match", options: "", substitution: "", description: nil },
            { pattern: "\\p{Emoji}+", test: "👨‍👩‍👧‍👦abc", result: "match", options: "", substitution: "", description: nil }
          ]
        },

        "POSIX Classes vs Unicode Properties" => {
          short: nil,
          description: nil,
          examples: [
            # --- Alphabetic Characters ---
            { pattern: "[[:alpha:]]+", test: "abc123XYZ", result: "match", options: "", substitution: "", description: nil },
            { pattern: "\\p{Alpha}+", test: "abc123XYZ", result: "match", options: "", substitution: "", description: nil },
            { pattern: "[[:^alpha:]]+", test: "abc123XYZ", result: "match", options: "", substitution: "", description: nil },
            { pattern: "\\P{Alpha}+", test: "abc123XYZ", result: "match", options: "", substitution: "", description: nil },

            # --- Digit Characters ---
            { pattern: "[[:digit:]]+", test: "abc123.45def", result: "match", options: "", substitution: "", description: nil },
            { pattern: "\\p{Digit}+", test: "abc123.45def", result: "match", options: "", substitution: "", description: nil },

            # --- Punctuation ---
            { pattern: "[[:punct:]]+", test: "hello!?", result: "match", options: "", substitution: "", description: nil },
            { pattern: "\\p{Punct}+", test: "hello!?", result: "match", options: "", substitution: "", description: nil },

            # --- Whitespace ---
            { pattern: "[[:space:]]+", test: "a b\tc\n", result: "match", options: "", substitution: "", description: nil },
            { pattern: "\\p{Space}+", test: "a b\tc\n", result: "match", options: "", substitution: "", description: nil },

            # --- Case Sensitivity ---
            { pattern: "[[:lower:]]+", test: "AbC", result: "match", options: "", substitution: "", description: nil },
            { pattern: "\\p{Lower}+", test: "AbC", result: "match", options: "", substitution: "", description: nil },
            { pattern: "[[:upper:]]+", test: "AbC", result: "match", options: "", substitution: "", description: nil },
            { pattern: "\\p{Upper}+", test: "AbC", result: "match", options: "", substitution: "", description: nil }

          ]
          }
        }

      # translate category short/description and example descriptions from locales
      orig.each do |name, data|
        key = name.parameterize
        data[:short] = I18n.t("regular_expressions.categories.#{key}.short")
        data[:description] = I18n.t("regular_expressions.categories.#{key}.description")
        data[:examples].each_with_index do |ex, i|
          ex[:description] = I18n.t("regular_expressions.categories.#{key}.examples.#{i}.description")
        end
      end

      orig
    end
end
