require 'rails_helper'

RSpec.describe "RegularExpressionFlow" do
  describe 'Header examples dropdown' do
    before { visit root_path }

    it 'ensures legacy examples panel is removed and reference panel is present' do
      # The examples panel used to live in the page body; it was moved to the
      # header dropdown. Assert we don't have the legacy container and that the
      # reference panel is still present on the page.
      expect(page).to have_no_css 'div#examples-panel', visible: :all
      expect(page).to have_css 'div#reference-panel'
    end

  describe 'Examples provided via header dropdown' do
      before do
        # open header dropdown which now houses the examples
        find('button[data-regexp-examples-target="caretButton"]', wait: true).click
      end

      it 'lists example categories and allows switching between them' do
        # Example categories should render inside the header dropdown
        RegularExpression::Example.categories.each do |(cat, data)|
          expect(page).to have_css("button[data-header-category='#{cat.to_s.parameterize}']", text: data[:short])
        end

        first_category = RegularExpression::Example.categories.keys.first
        find("button[data-header-category='#{first_category.to_s.parameterize}']").click

        # ensure at least the first example's pattern is present in the header items
        first_ex = RegularExpression::Example.categories[first_category][:examples].first
        within('[data-regexp-examples-target="headerItemsScroll"]') do
          examples = all('button[data-regexp-examples-target="example"]', minimum: 1)
          patterns = examples.map { |el| el['data-pattern'].to_s }
          expect(patterns).to include(first_ex[:pattern])
        end
      end

      it 'applies an example from the header dropdown when clicked' do
        # choose a category (fallback to first)
        first_category = RegularExpression::Example.categories.keys.first
        find("button[data-header-category='#{first_category.to_s.parameterize}']", wait: true).click

        # Find and click the first example inside the header dropdown by matching its data-pattern
        first_ex = RegularExpression::Example.categories[first_category][:examples].first
        examples = all('[data-regexp-examples-target="example"]', minimum: 1)
        example = examples.find { |el| el['data-pattern'].to_s == first_ex[:pattern].to_s }
        expect(example).to be_present
        example.click

        # basic assertions: pattern was applied and match highlights appear
        expect(find('textarea#regular_expression_expression').value).to include(first_ex[:pattern])
        expect(page).to have_css 'mark', visible: :all
      end
    end
  end

  describe 'RegularExpressions UI (i18n)' do
    it 'switches UI to Japanese when toggling language from header' do
      visit root_path

      # Ensure there is a match result visible by applying a trivial example
      # so the match partial (with wrap/show labels) is rendered, then toggle
      # language and assert translations.
      find('textarea#regular_expression_expression').set('foo')
      find('textarea#regular_expression_test_string').set('foo')
      page.execute_script("document.querySelector('form[data-controller=\\\"regexp-form\\\"]') && document.querySelector('form[data-controller=\\\"regexp-form\\\"]').requestSubmit()")

      # Now toggle locale (link merges current params so the same pattern/test are kept)
      first('[data-test="locale-toggle"]').click

      # The locale toggle reloads the page; assert global header label changed to Japanese
      expect(page).to have_text(I18n.t('regular_expressions.header.lang_label', locale: :ja))

      # The results frame may be re-rendered without preserving the in-frame state
      within('turbo-frame#regexp') do
        expect(page).to have_text(I18n.t('regular_expressions.results.test_result_placeholder', locale: :ja), wait: 5)
      end
    end
  end

  describe "Normal behavior: Matching and substitution" do
    before { visit root_path }

    it 'displays the initial view' do
      # Header section
      expect(page).to have_css 'span#example-link', text: 'Rubree'
      expect(page).to have_css 'p', text: I18n.t('regular_expressions.header.subtitle')
      expect(page).to have_css 'span#example-link', text: I18n.t('regular_expressions.header.try_example'), class: /text-blue-400/

      # Regular expression and options form
      expect(page).to have_css 'label', text: 'Your regular expression:'
      expect(page).to have_field 'regular_expression[regular_expression]', with: ''
      expect(page).to have_css 'span', text: 'Options:'
      expect(page).to have_field 'regular_expression[options]', with: ''

      # Test string and substitution form
      expect(page).to have_css 'label', text: 'Your test string:'
      expect(page).to have_field 'regular_expression[test_string]', with: ''
      expect(page).to have_css 'span', text: I18n.t('regular_expressions.form.substitution')
      expect(page).to have_field 'regular_expression[substitution_string]', with: ''

      # Output section (results and diagrams)
      expect(page).to have_css 'p', text: 'Railroad diagram will appear here'
      expect(page).to have_css 'p', text: 'Regexp test result will appear here'

      # Reference section (examples are now in the header dropdown)
      expect(page).to have_css 'span#reference-label', text: 'Regex Quick Reference'
      expect(page).to have_css 'div#reference-panel'

      # Footer section
      # check for the common fragment to avoid punctuation/quote style mismatches
      expect(page).to have_text(/Inspired by Michael Lovitt’s excellent/)
      expect(page).to have_css 'a', text: 'Rubular', class: /text-blue-700/
    end

    it 'applies an example and shows match/substitution results (fast)' do
      # click Try an example and assert the important outcomes only
      find('span#example-link', text: I18n.t('regular_expressions.header.try_example'), wait: true).click

      # test string should be populated with today's date fragment
      expect(find('textarea#regular_expression_test_string').value).to include(Date.today.strftime('%-m/%-d/%Y'))

      # the result frame should be present and contain the matched and substituted dates
      expect(page).to have_css 'turbo-frame#regexp', visible: :visible
      matched_date = Date.today.strftime('%-m/%-d/%Y')
      substituted_date = Date.today.strftime('%Y/%-m/%-d')
      expect(page).to have_css 'mark', text: matched_date
      expect(page).to have_css 'mark', text: substituted_date
    end

    it 'header interactions: reset, dice, caret and dropdown (fast)' do
      # clicking Rubree resets inputs
      find('span#example-link', text: I18n.t('regular_expressions.header.try_example')).click
      find('span#example-link', text: 'Rubree').click
      expect(find('textarea#regular_expression_expression').value).to eq('')
      expect(find('textarea#regular_expression_test_string').value).to eq('')

      # dice button briefly animates — avoid relying on hover/tooltips by invoking click via JS
      # This removes fragile UI microinteraction dependency (tooltips, hover) from the test.
      page.execute_script("document.querySelector('button[data-regexp-examples-target=\"diceButton\"]').click()")
      expect(page).to have_css('button[data-regexp-examples-target="diceButton"].animate-bounce', wait: 0.8)

      # caret opens dropdown and scroll container exists
      find('button[data-regexp-examples-target="caretButton"]', wait: true).click
      selector = '[data-regexp-examples-target="headerScroll"]'
      expect(page).to have_selector(selector, visible: :visible)
      expect(page).to have_css("#{selector} button", minimum: 1)
    end
  end

  describe "Regex Syntax: Named capture groups" do
    before { visit root_path }

    it "matches with valid Ruby-style named group" do
      fill_in "regular_expression[regular_expression]", with: '(?<word>foo)'
      fill_in "regular_expression[test_string]", with: 'foo bar foo'

      # Railroad diagram section
      expect(page).to have_css 'svg'

      # Match result section
      expect(page).to have_css 'mark', text: 'foo', count: 2, class: /bg-blue-200/

      # Match groups section
      expect(page).to have_css 'label', text: 'Match 1', class: /text-yellow-400/
      expect(page).to have_css 'span.bg-yellow-200', text: 'word', count: 2
      expect(page).to have_css 'code.text-white', text: 'foo', count: 2
      expect(page).to have_css 'label', text: 'Match 2', class: /text-yellow-400/
    end

    it "shows error for Python-style named group syntax" do
      fill_in "regular_expression[regular_expression]", with: '(?P<name>Alice)'
      fill_in "regular_expression[test_string]", with: 'Alice'

      # Railroad diagram section
      expect(page).to have_css 'div', text: 'Invalid pattern: undefined group option:', class: /bg-red-100/

      # Match result section
      expect(page).to have_css 'div', text: 'Invalid regular expression.', class: /bg-red-100/
    end

    it "shows error for malformed named group" do
      fill_in "regular_expression[regular_expression]", with: '(?<nameAlice)'
      fill_in "regular_expression[test_string]", with: 'Alice'

      # Railroad diagram section
      expect(page).to have_css 'div', text: 'Invalid pattern: invalid group name', class: /bg-red-100/

      # Match result section
      expect(page).to have_css 'div', text: 'Invalid regular expression.', class: /bg-red-100/
    end
  end

  describe "Regex Syntax: Character classes" do
    before { visit root_path }

    it "matches using valid character class [abc]" do
      fill_in "regular_expression[regular_expression]", with: '[abc]'
      fill_in "regular_expression[test_string]", with: 'cab'

      # Railroad diagram section
      expect(page).to have_css 'svg'

      # Match result section
      expect(page).to have_css 'mark', text: 'c', class: /bg-blue-200/
      expect(page).to have_css 'mark', text: 'a', class: /bg-blue-200/
      expect(page).to have_css 'mark', text: 'b', class: /bg-blue-200/
    end

    it "shows error for unterminated character class" do
      fill_in "regular_expression[regular_expression]", with: '[abc'
      fill_in "regular_expression[test_string]", with: 'abc'

      # Railroad diagram section
      expect(page).to have_css 'div', text: 'Invalid pattern: premature end of char-class:', class: /bg-red-100/

      # Match result section
      expect(page).to have_css 'div', text: 'Invalid regular expression.', class: /bg-red-100/
    end

    it "shows error for invalid range in character class" do
      fill_in "regular_expression[regular_expression]", with: '[z-a]'
      fill_in "regular_expression[test_string]", with: 'abc'

      # Railroad diagram section
      expect(page).to have_css 'div', text: 'Invalid pattern: empty range in char class:', class: /bg-red-100/

      # Match result section
      expect(page).to have_css 'div', text: 'Invalid regular expression.', class: /bg-red-100/
    end
  end

  describe "Regex Syntax: Grouping and parentheses" do
    before { visit root_path }

    it "matches with valid grouping (abc)" do
      fill_in "regular_expression[regular_expression]", with: '(abc)'
      fill_in "regular_expression[test_string]", with: 'abc abc'

      # Railroad diagram section
      expect(page).to have_css 'svg'

      # Match result section
      expect(page).to have_css 'mark', text: 'abc', count: 2, class: /bg-blue-200/

      # Match groups section
      expect(page).to have_css 'label', text: 'Match 1', class: /text-blue-300/
      expect(page).to have_css 'span.text-white', text: '1.', count: 2
      expect(page).to have_css 'code.text-white', text: 'abc', count: 2
      expect(page).to have_css 'label', text: 'Match 2', class: /text-blue-300/
    end

    it "shows error for unmatched open parenthesis" do
      fill_in "regular_expression[regular_expression]", with: '(abc'
      fill_in "regular_expression[test_string]", with: 'abc'

      # Railroad diagram section
      expect(page).to have_css 'div', text: 'Invalid pattern: end pattern with unmatched parenthesis:', class: /bg-red-100/

      # Match result section
      expect(page).to have_css 'div', text: 'Invalid regular expression.', class: /bg-red-100/
    end

    it "shows error for unmatched close parenthesis" do
      fill_in "regular_expression[regular_expression]", with: 'abc)'
      fill_in "regular_expression[test_string]", with: 'abc'

      # Railroad diagram section
      expect(page).to have_css 'div', text: 'Invalid pattern: unmatched close parenthesis:', class: /bg-red-100/

      # Match result section
      expect(page).to have_css 'div', text: 'Invalid regular expression.', class: /bg-red-100/
    end

    it "captures groups correctly in nested parentheses" do
      fill_in "regular_expression[regular_expression]", with: '(abc (def))'
      fill_in "regular_expression[test_string]", with: 'abc def'

      # Railroad diagram section
      expect(page).to have_css 'svg'

      # Match result section
      expect(page).to have_css 'mark', text: 'abc', class: /bg-blue-200/
      expect(page).to have_css 'mark', text: 'def', class: /bg-blue-200/
    end

    it 'shows a friendly error in the results area when named capture access with multibyte name fails' do
      visit root_path

      # use precise selectors for the textareas
      find('textarea#regular_expression_expression').set('(?<名前>foo)')
      find('textarea#regular_expression_test_string').set('foo')

      # Submit the form via JS to mimic the real app behavior
      page.execute_script("document.querySelector('form[data-controller=\\\"regexp-form\\\"]') && document.querySelector('form[data-controller=\\\"regexp-form\\\"]').requestSubmit()")

      within('turbo-frame#regexp') do
        expect(page).to have_css('div.bg-red-100', wait: 5)
        expect(page).to have_text(/Invalid named capture access|Invalid regular expression/)
      end
    end
  end

  describe "Matching behavior with test string" do
    before { visit root_path }

    it "highlights matches when present" do
      fill_in "regular_expression[regular_expression]", with: 'foo'
      fill_in "regular_expression[test_string]", with: 'foo bar foo'

      # Railroad diagram section
      expect(page).to have_css 'svg'

      # Match result section
      expect(page).to have_css 'mark', text: 'foo', count: 2, class: /bg-blue-200/
    end

    it "shows 'No matches.' when pattern does not match" do
      fill_in "regular_expression[regular_expression]", with: 'foo'
      fill_in "regular_expression[test_string]", with: 'bar'

      # Railroad diagram section
      expect(page).to have_css 'svg'

      # Match result section
      expect(page).to have_css 'div', text: 'No matches.', class: /bg-red-100/
    end
  end

  describe "Substitution functionality" do
    before { visit root_path }

    it "performs substitution using backreference \\1" do
      fill_in "regular_expression[regular_expression]", with: '(foo)'
      fill_in "regular_expression[test_string]", with: 'foo foo'
      fill_in "regular_expression[substitution_string]", with: '\\1!'

      # Match result section
      expect(page).to have_css 'mark', text: 'foo', count: 2, class: /bg-blue-200/

      # Substitution result section
      expect(page).to have_css 'mark', text: 'foo!', count: 2, class: /bg-green-300/
    end

    it "performs substitution with multiple groups" do
      fill_in "regular_expression[regular_expression]", with: '(foo)(bar)'
      fill_in "regular_expression[test_string]", with: 'foobar'
      fill_in "regular_expression[substitution_string]", with: '\\2\\1'

      # Match result section
      expect(page).to have_css 'mark', text: 'foobar', class: /bg-blue-200/

      # Substitution result section
      expect(page).to have_css 'mark', text: 'barfoo', class: /bg-green-300/
    end

    it "ignores invalid backreference \\2 in substitution" do
      fill_in "regular_expression[regular_expression]", with: '(foo)'
      fill_in "regular_expression[test_string]", with: 'foo'
      fill_in "regular_expression[substitution_string]", with: '\\2!'

      # Match result section
      expect(page).to have_css 'mark', text: 'foo', class: /bg-blue-200/

      # Substitution result section
      expect(page).to have_css 'mark', text: 'foo!', count: 0
    end
  end

  describe "Input validation" do
    before { visit root_path }

    it "shows message when both fields are empty" do
      fill_in "regular_expression[regular_expression]", with: ''
      fill_in "regular_expression[test_string]", with: ''

      # Railroad diagram section
      expect(page).to have_css 'p', text: 'Railroad diagram will appear here'

      # Match result section
      expect(page).to have_css 'p', text: 'Regexp test result will appear here'
    end

    it "shows message when only test string is empty" do
      fill_in "regular_expression[regular_expression]", with: 'abc'
      fill_in "regular_expression[test_string]", with: ''

      # Railroad diagram section
      expect(page).to have_css 'svg'

  # Match result section
  expect(page).to have_css 'p', text: I18n.t('regular_expressions.results.please_enter')
    end

    it "shows message when only regex pattern is empty" do
      fill_in "regular_expression[regular_expression]", with: ''
      fill_in "regular_expression[test_string]", with: 'abc'

      # Railroad diagram section
      expect(page).to have_css 'p', text: 'Railroad diagram will appear here'

      # Match result section
      expect(page).to have_css 'p', text: I18n.t('regular_expressions.results.please_enter')
    end
  end

  describe "Ruby code display functionality", :js do
    before do
      visit root_path
      find('span#example-link', text: I18n.t('regular_expressions.header.try_example')).click
    end

    it "shows and hides Ruby code block when toggling the code pill" do
      # Ruby code display section
      # The toggle is now a pill control with an accessible label (sr-only) and role="button".
      label_text = I18n.t('regular_expressions.results.ruby_code_label')
      label_el = find('label', text: label_text)
      toggle_button = label_el.find('[role="button"]')

      # initially collapsed
      expect(toggle_button['aria-expanded']).to eq 'false'
      expect(page).to have_no_selector('div[x-show="show"]', visible: :visible)

      # open
      toggle_button.click
      expect(toggle_button['aria-expanded']).to eq 'true'
      expect(page).to have_css('div[x-show="show"]', visible: :visible)

      # close
      toggle_button.click
      expect(toggle_button['aria-expanded']).to eq 'false'
      expect(page).to have_no_selector('div[x-show="show"]', visible: :visible)
    end
  end

  describe "Regex options: Flags (i, m, x) behavior" do
    before { visit root_path }

    it "enables case-insensitive matching with 'i' option" do
      fill_in "regular_expression[regular_expression]", with: 'foo'
      fill_in "regular_expression[test_string]", with: 'FOO'
      fill_in "regular_expression[options]", with: 'i'

      # Match result section
      expect(page).to have_css 'mark', text: 'FOO', class: /bg-blue-200/
    end

    it "enables multiline matching with 'm' option" do
      fill_in "regular_expression[regular_expression]", with: '^foo'
      fill_in "regular_expression[test_string]", with: "bar\nfoo"
      fill_in "regular_expression[options]", with: 'm'

      # Match result section
      expect(page).to have_css 'mark', text: 'foo', class: /bg-blue-200/
    end

    it "enables extended mode (allow comments/spaces) with 'x' option" do
      fill_in "regular_expression[regular_expression]", with: "f o o # match foo"
      fill_in "regular_expression[test_string]", with: 'foo'
      fill_in "regular_expression[options]", with: 'x'

      # Match result section
      expect(page).to have_css 'mark', text: 'foo', class: /bg-blue-200/
    end

    it "enables multiple flags together" do
      fill_in "regular_expression[regular_expression]", with: "^foo"
      fill_in "regular_expression[test_string]", with: "FOO\nfoo"
      fill_in "regular_expression[options]", with: 'im'

      # Railroad diagram section
      expect(page).to have_css 'svg'

      # Match result section
      expect(page).to have_css 'mark', text: 'FOO', class: /bg-blue-200/
      expect(page).to have_css 'mark', text: 'foo', class: /bg-blue-200/
    end
  end

  describe "Match result display options", :js do
    before do
      visit root_path
      page.execute_script("localStorage.clear()")
      visit current_path
    end

    it "toggles Wrap words option and checks applied CSS classes" do
      fill_in "regular_expression[regular_expression]", with: 'foo'
      fill_in "regular_expression[test_string]", with: 'foo bar foo'

      # Match result section
      wrap_checkbox = find('input[type=checkbox][x-model=wrap]')
      expect(wrap_checkbox).to be_checked

      match_result_div = all('div.bg-gray-900', text: /foo/).find do |el|
        el[:class].include?('whitespace-pre-wrap')
      end
      expect(match_result_div).not_to be_nil
      expect(match_result_div[:class]).to include('break-words')

      wrap_checkbox.uncheck
      expect(wrap_checkbox).not_to be_checked

      match_result_div_after = all('div.bg-gray-900', text: /foo/).find do |el|
        el[:class].include?('whitespace-pre')
      end
      expect(match_result_div_after).not_to be_nil
      expect(match_result_div[:class]).to include('overflow-x-auto')
    end

    it "toggles Show invisibles option and verifies visibility of line breaks" do
      fill_in "regular_expression[regular_expression]", with: 'foo'
      fill_in "regular_expression[test_string]", with: "foo bar foo\nfoo bar foo"

      # Match result section
      show_invisibles_checkbox = find('input[type=checkbox][x-model=showInvisibles]')
      show_invisibles_checkbox.uncheck
      expect(show_invisibles_checkbox).not_to be_checked

      expect(page).to have_no_content 'foo bar foo⏎'

      show_invisibles_checkbox.check
      expect(show_invisibles_checkbox).to be_checked

      expect(page).to have_content 'foo bar foo⏎'
    end
  end

  describe 'Regex Quick Reference' do
    before { visit root_path }

    it 'displays section titles and code examples correctly' do
      RegularExpression::Reference.sections.each do |section|
        expect(page).to have_content(section[:title])

        section[:items].each do |code, description|
          expect(page).to have_content(code)
          expect(page).to have_content(description)
          expect(page).to have_css "code", text: code
        end
      end
    end
  end
end
