# Roadmap

- [x] **Basic Match Handling**: Provides functionality to match regular expressions against test strings.
- [x] **Match Positions**: Supports the extraction and display of match start and end positions.
- [x] **Capture Groups**: Extracts and displays capture groups from regex matches.
- [x] **Named Captures**: Supports capturing named groups from regex matches.
- [x] **Regex Quick Reference**: Provides a concise list of commonly used regex syntax for quick reference.
- [x] **Regex Examples**: Interactive examples to test and visualize regex patterns in real-time.
- [x] **Execution Time Measurement**: Measures and reports the execution time of regex operations.
- [x] **Regex Diagram Generation**: Generates and visualizes regex patterns using SVG diagrams.
- [x] **Regex Substitution Function**: Supports regex-based string substitution.
- [x] **Ruby Code Snippet Generation**: Automatically generates Ruby code snippets for testing regex patterns.
- [x] **Web Interface for Regex Testing**: Interactive web UI to test and visualize regular expressions in real-time.
- [x] **Permalink / Shareable URL generation**: Create shareable URLs that encode the editor state (regex, sample text, and options) for easy reproduction.
- [x] **ReDoS Check Integration**: Check regular expressions for ReDoS vulnerabilities via embedded recheck Playground with one-click pattern copying. ([#306](https://github.com/aim2bpg/rubree/issues/306))

---

## Supported Scope of `Regexp::Parser` Used for SVG Output in `Railroad Diagrams`

- [x] **Alternation**: `a\|b\|c`
- [x] **Anchors**: `\A`, `^`, `\b`
- [x] **Character Classes**: `[abc]`, `[^\\]`, `[a-d&&aeiou]`
- [x] **Character Types**: `\d`, `\H`, `\s`
- [x] **Cluster Types**: `\R`, `\X`
- [x] **Conditional Expressions**: `(?(cond)yes-subexp)`, `(?(cond)yes-subexp\|no-subexp)`
- [x] **Escape Sequences**: `\t`, `\\+`, `\?`
- [x] **Free Space**: whitespace and `# Comments` _(x modifier)_
- [x] **Grouped Expressions**:
  - [x] **Assertions**:
    - [x] **Lookahead**: `(?=abc)`
    - [x] **Negative Lookahead**: `(?!abc)`
    - [x] **Lookbehind**: `(?<=abc)`
    - [x] **Negative Lookbehind**: `(?<!abc)`
  - [x] **Atomic**: `(?>abc)`
  - [x] **Absence**: `(?~abc)`

- [x] **Back-references**:
  - [x] **Named**: `\k<name>`
  - [x] **Nest Level**: `\k<n-1>`
  - [x] **Numbered**: `\k<1>`
  - [x] **Relative**: `\k<-2>`
  - [x] **Traditional**: `\1` through `\9`

- [x] **Capturing**: `(abc)`
- [x] **Comments**: `(?# comment text)`
- [x] **Named Captures**: `(?<name>abc)`, `(?'name'abc)`
- [x] **Options**: `(?mi-x:abc)`, `(?a:\s\w+)`, `(?i)`
- [x] **Passive Captures**: `(?:abc)`
- [x] **Subexpression Calls**: `\g<name>`, `\g<1>`

- [x] **Keep**: `\K`, `(ab\Kc\|d\Ke)f`

- [x] **Literals** _(utf-8)_:
  - [x] `Ruby`, `ルビー`, `روبي`

- [x] **POSIX Classes**:
  - [x] `[:alpha:]`, `[:^digit:]`

- [ ] **Quantifiers**:
  - [x] **Greedy**: `?`, `*`, `+`, `{m,M}`
  - [ ] **Reluctant (Lazy)**: `??`, `*?`, `+?`
    > Simple lazy forms (`*?`, `+?`, `??`) are accepted and rendered with a "(lazy)" comment label
    > in the diagram. Range forms (`{m,M}?`) raise an error and show an error message instead of a
    > diagram — `railroad_diagrams` gem does not support the range+lazy/possessive combination.
  - [ ] **Possessive**: `?+`, `*+`, `++`
    > Same as lazy: simple possessive forms show a "(possessive)" comment label; range forms
    > (`{m,M}+`) show an error message.

- [ ] **String Escapes**:
  - [x] **Control**: `\C-C`, `\cD`
  - [x] **Hex**: `\x20`, `\xE2\x82\xAC`
  - [ ] **Meta**: `\M-c`, `\M-\C-C`, `\M-\cC`, `\C-\M-C`, `\c\M-C`
  - [x] **Octal**: `\0`, `\01`, `\012`
  - [x] **Unicode**: `\uHHHH`, `\u{H+ H+}`

- [x] **Unicode Properties** _(Unicode 15.0.0)_:
  - [x] **Age**: `\p{Age=5.2}`, `\P{age=7.0}`, `\p{^age=8.0}`
  - [x] **Blocks**: `\p{InArmenian}`, `\P{InKhmer}`, `\p{^InThai}`
  - [x] **Classes**: `\p{Alpha}`, `\P{Space}`, `\p{^Alnum}`
  - [x] **Derived**: `\p{Math}`, `\P{Lowercase}`, `\p{^Cased}`
  - [x] **General Categories**: `\p{Lu}`, `\P{Cs}`, `\p{^sc}`
  - [x] **Scripts**: `\p{Arabic}`, `\P{Hiragana}`, `\p{^Greek}`
  - [x] **Simple**: `\p{Dash}`, `\p{Extender}`, `\p{^Hyphen}`

---

For more detailed information about supported syntax, refer to the official documentation:
[Supported Syntax - Regexp::Parser GitHub README](https://github.com/ammar/regexp_parser/blob/master/README.md#supported-syntax)
