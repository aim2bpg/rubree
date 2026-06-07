---
name: architecture-philosophy
description: Why Rubree models domain logic as ActiveModel-based POROs in app/models instead of service objects or form objects, how classes get named and split up, and why coverage is visualized. Use when adding new domain logic, deciding where new code should live, naming a new class, weighing whether to introduce a service or form object, or reviewing a PR or diff. For frontend conventions (Alpine.js, Stimulus, Turbo, ERB, SVG), see the frontend-patterns skill.
---

# Architecture Philosophy

This is not a generic Rails pattern — it is a direction this project reached on purpose, through
review and iteration. If you are about to suggest `app/services/` or `app/forms/` because that is
the common pattern in Rails tutorials and most training data, **stop and read this first**. It
describes the considered, forward direction for this project — not just a snapshot of its history.

## Put domain logic in ActiveModel-based models, in `app/models`

**The rule**: when you need an object that is not backed by a database table — a calculation, a
coordinator that pulls data from several sources, an input object for a multi-step form — write a
plain Ruby class that includes `ActiveModel::Model`, give it `attr_accessor`/`validates` like any
other Rails model, and place it in `app/models/` (namespaced under a related domain class where
one exists). This is what every non-AR domain object in Rubree already looks like:

```ruby
# ✅ app/models/regular_expression/substitution.rb — a PORO that behaves like a Rails model
class RegularExpression
  class Substitution
    include ActiveModel::Model

    attr_accessor :regular_expression, :test_string, :substitution_string
    attr_reader :substitution_result

    validates :regular_expression, presence: true
    validates :test_string, presence: true
    validate :validate_capture_references

    def initialize(regular_expression:, test_string:, substitution_string:)
      @regular_expression = regular_expression
      # ...
      run_substitution if @regexp && !substitution_string.nil?
    end
  end
end
```

```ruby
# ❌ what this would look like as a "service object" — a separate concern, a separate
# directory, a separate convention for the team to remember and keep aligned on
class Services::SubstitutionService
  def initialize(regular_expression, test_string, substitution_string)
    # ... no validations, no ActiveModel::Errors, no shared Rails idiom — reinvents
    # what ActiveModel already gives a model for free
  end

  def call
    # ...
  end
end
```

**Do not** create `app/services/` or `app/forms/` directories for new code. Both ideas are
already covered by the same technique:

- A "service object" is, in most cases, logic that fits directly on (or next to) an
  ActiveModel-based model — Rails already gives you validations, callbacks, and attributes there
- A "form object" *is* an ActiveModel-based PORO by definition — see
  [speakerdeck.com/expajp/an-introduction-to-formobject](https://speakerdeck.com/expajp/an-introduction-to-formobject):
  it is defined as "a Ruby object not backed by a database table, built by including
  `ActiveModel::Model`". There is no separate pattern to reach for; `app/models` is already where
  it belongs

**Why this is the direction, not just a habit it fell into**: Rubree used to have both
`app/services` and `app/forms`. During an external code review (Oct 2025), the reviewer
pointed out that ActiveModel-based models conventionally live in `app/models` — citing
[Rails Guides → Active Model Basics](https://railsguides.jp/active_model_basics.html) — and that
most of the `app/services` logic could be modeled the same way. The maintainer then consolidated
everything into `app/models`; that consolidation *is* the current architecture
(`RegularExpression`, `RegularExpression::RailroadDiagram`, `RegularExpression::Substitution`,
and so on).

This also lines up with what experienced Rails developers have converged on after years of
leaning on service objects — see
[joker1007, "今改めてServiceクラスについて考える"](https://speakerdeck.com/joker1007/jin-gai-meteservicekurasunituitekao-eru-arurailskai-fa-zhe-no10nian):
his conclusion, after a decade of recommending service classes, was that the difficulty of
keeping a whole team aligned on "where logic should live" rarely pays for itself — and that
leaning on `ActiveRecord`/`ActiveModel` plus a clear domain model gets further with less
overhead.

## Name classes after what they are, not what they do

```ruby
# ✅ nouns — what the object is (the actual classes in app/models/regular_expression/)
RegularExpression::RailroadDiagram
RegularExpression::Substitution
RegularExpression::Example
RegularExpression::Reference

# ❌ verb-shaped — what the object does; this is the shape service-object naming pulls toward
RegularExpression::BuildRailroadDiagram
RegularExpression::GenerateExample
RegularExpression::PerformSubstitution
```

This came directly out of review feedback on this project. Noun names keep a class's
responsibility legible at a glance, and steer away from the "do-something" naming that
service-object thinking tends to produce.

## When splitting a class up, optimize for readability, not file count

`RailroadDiagram` was refactored into modules with its case-when label logic grouped per
`Regexp::Expression` class — but the maintainer deliberately stopped there after trying to go
further:

> 一時、さらにクラス・ファイルを細分化したりと試行錯誤してみましたが、逆に構造が断片的となって
> 処理を追うのが大変になりそうな気がしましたので、このくらいの粒度でベタに case-when の処理が
> 並んでいてもいいのかな
>
> ("I experimented with splitting it into even more classes and files, but that left the
> structure feeling fragmented and harder to follow — so I think it's fine to leave a flat
> case-when at roughly this grain.")

Treat that as the working default: a few well-named, slightly larger modules beat many small ones
if the split makes the flow harder to trace.

## Make test quality visible, not just enforced

Coverage is visualized through octocov (see the `testing-guidelines` skill) because — in the
maintainer's words — "without seeing coverage, it was hard to tell whether the tests were
actually good" (整備にあたっては、カバレッジを意識しなければ良し悪しがよく分かりませんでした).
The percentage is not the point; the point is giving a future reader — human or AI — a way to
*see* whether the suite actually exercises the paths that matter.

## Use modules for static lookups, classes for stateful domain objects

Within `app/models/regular_expression/`, there are two distinct shapes of object:

```ruby
# ✅ module_function — no instance state; pure lookup or data mapping
#    (Example, Reference, RailroadDiagramBuilder)
class RegularExpression
  module Example
    module_function

    def categories   # reads i18n YAML, returns a hash — no state to hold
      ...
    end
  end
end

# ✅ class + include ActiveModel::Model — holds a result, runs validations
#    (Substitution, RubyCode, RailroadDiagram)
class RegularExpression
  class RailroadDiagram
    include ActiveModel::Model
    attr_reader :error_message
    validate :check_for_lazy_or_possessive_quantifiers

    def generate   # produces a result stored on self
      ...
    end
  end
end
```

The rule: reach for `module_function` when the object is a pure lookup or transform with no
per-request state. Reach for a class with `include ActiveModel::Model` when the object holds a
result (`attr_reader :substitution_result`), runs validations, or has a lifecycle tied to a
request. Don't flip the choice just because a module grows large — size alone is not the signal.

---

## A note for Claude specifically

An AI agent will, on average, suggest the generic Rails pattern — service objects, form objects
as separate concerns — because that is what most training data favors. That is a pull toward the
*statistically common* answer, not necessarily the *right* one for this project. This document
exists so that pull does not quietly bring `app/services`/`app/forms` back over time. If you find
yourself about to propose one, re-read the first section before you do.

---

## Review checklist

When reviewing a PR or diff — whether via `/code-review`, `/code-review --comment`, or a manual
pass — work through these before commenting. They encode the things most likely to drift in a
near-solo project where there is no second human reviewer to catch them.

### Architecture

- [ ] New domain logic lives in `app/models/` as an ActiveModel-based PORO — no `app/services/`
  or `app/forms/` introduced
- [ ] New class names are nouns (`RegularExpression::Foo`), not verb-shaped
  (`PerformFoo`, `FooService`)
- [ ] If a class was split further, the split makes the flow *easier* to trace — not just smaller
  files

### Client-side philosophy

See the `frontend-patterns` skill for the full checklist.

### Tests

See the `testing-guidelines` skill for the full checklist — spec layer choice, description style,
mocking patterns, `data-*` selector rule, and the octocov coverage/ratio/time thresholds.

### Security

See the `ci-cd-pipeline` skill — Brakeman (SAST) and Gitleaks (secret scan) both run on
`pre-commit` and in CI. If either fails locally, fix the root cause rather than skipping the hook.
