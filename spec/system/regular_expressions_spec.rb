require 'rails_helper'

include RegularExpressionsHelper

RSpec.describe "RegularExpressionFlow" do
  describe "Normal behavior: Matching and substitution" do
    it 'initial view' do
      visit root_path

      # Check content on the top page
      expect(page).to have_content('Rubree')
      expect(page).to have_content('a Ruby regular expression editor')

      # Ensure input sections are rendered
      expect(page).to have_content('Your regular expression:')
      expect(page).to have_content('Your test string:')
      expect(page).to have_content('Substitution:')
    end

    it 'displays match and substitution results for example input' do
      visit root_path

      # Click "Try an example" to auto-fill fields
      find('span', text: 'Try an example').click

      # Ensure the railroad diagram is shown
      expect(page).to have_content('Railroad diagram:')
      expect(page).to have_css('svg')

      # Ensure match result includes today's date
      expect(page).to have_content('Match result:')
      matched_date = Date.today.strftime('%-m/%-d/%Y')
      expect(page).to have_content("Today's date is: #{matched_date}")
      expect(page).to have_css('mark', text: matched_date)

      # Check the execution time is displayed correctly
      expect(page).to have_content('ms (avg of 5 runs)')

      # Check each capture group is displayed correctly
      expect(page).to have_content('Match groups:')
      expect(page).to have_css('mark', text: Date.today.strftime('%-m'))
      expect(page).to have_css('mark', text: Date.today.strftime('%-d'))
      expect(page).to have_css('mark', text: Date.today.strftime('%Y'))

      # Check the substitution result is correctly shown
      expect(page).to have_content('Substitution result:')
      substituted_date = Date.today.strftime('%Y/%-m/%-d')
      expect(page).to have_content("Today's date is: #{substituted_date}")
      expect(page).to have_css('mark', text: substituted_date)

      # Check if Ruby code section is displayed
      expect(page).to have_content('Ruby code:')
    end
  end

  describe "Regex Syntax: Character classes" do
    before { visit root_path }

    it "matches using valid character class [abc]" do
      fill_in "regular_expression[expression]", with: '[abc]'
      fill_in "regular_expression[test_string]", with: 'cab'
      expect(page).to have_css('mark', text: 'c')
      expect(page).to have_css('mark', text: 'a')
      expect(page).to have_css('mark', text: 'b')
    end

    it "shows error for unterminated character class" do
      fill_in "regular_expression[expression]", with: '[abc'
      fill_in "regular_expression[test_string]", with: 'abc'
      expect(page).to have_content('Invalid Pattern: premature end of char-class:')
      expect(page).to have_content('Invalid regular expression.')
    end

    it "shows error for invalid range in character class" do
      fill_in "regular_expression[expression]", with: '[z-a]'
      fill_in "regular_expression[test_string]", with: 'abc'
      expect(page).to have_content('Invalid Pattern: empty range in char class:')
      expect(page).to have_content('Invalid regular expression.')
    end
  end

  describe "Regex Syntax: Grouping and parentheses" do
    before { visit root_path }

    it "matches with valid grouping (abc)" do
      fill_in "regular_expression[expression]", with: '(abc)'
      fill_in "regular_expression[test_string]", with: 'abc abc'
      expect(page).to have_css('mark', text: 'abc', count: 2)
    end

    it "shows error for unmatched open parenthesis" do
      fill_in "regular_expression[expression]", with: '(abc'
      fill_in "regular_expression[test_string]", with: 'abc'
      expect(page).to have_content('Invalid Pattern: end pattern with unmatched parenthesis:')
      expect(page).to have_content('Invalid regular expression.')
    end

    it "shows error for unmatched close parenthesis" do
      fill_in "regular_expression[expression]", with: 'abc)'
      fill_in "regular_expression[test_string]", with: 'abc'
      expect(page).to have_content('Invalid Pattern: unmatched close parenthesis:')
      expect(page).to have_content('Invalid regular expression.')
    end
  end

  describe "Regex Syntax: Named capture groups" do
    before { visit root_path }

    it "matches with valid Ruby-style named group" do
      fill_in "regular_expression[expression]", with: '(?<word>foo)'
      fill_in "regular_expression[test_string]", with: 'foo bar foo'
      expect(page).to have_css('mark', text: 'foo', count: 2)
    end

    it "shows error for Python-style named group syntax" do
      fill_in "regular_expression[expression]", with: '(?P<name>Alice)'
      fill_in "regular_expression[test_string]", with: 'Alice'
      expect(page).to have_content('Invalid Pattern: undefined group option:')
      expect(page).to have_content('Invalid regular expression.')
    end

    it "shows error for malformed named group" do
      fill_in "regular_expression[expression]", with: '(?<nameAlice)'
      fill_in "regular_expression[test_string]", with: 'Alice'
      expect(page).to have_content('Invalid Pattern: invalid group name')
      expect(page).to have_content('Invalid regular expression.')
    end
  end

  describe "Matching behavior with test string" do
    before { visit root_path }

    it "highlights matches when present" do
      fill_in "regular_expression[expression]", with: 'foo'
      fill_in "regular_expression[test_string]", with: 'foo bar foo'
      expect(page).to have_css('mark', text: 'foo', count: 2)
    end

    it "shows 'No matches.' when pattern does not match" do
      fill_in "regular_expression[expression]", with: 'foo'
      fill_in "regular_expression[test_string]", with: 'bar'
      expect(page).to have_css('svg')
      expect(page).to have_content('No matches.')
    end
  end

  describe "Substitution functionality" do
    before { visit root_path }

    it "performs substitution using backreference \\1" do
      fill_in "regular_expression[expression]", with: '(foo)'
      fill_in "regular_expression[test_string]", with: 'foo foo'
      fill_in "regular_expression[substitution]", with: '\\1!'
      expect(page).to have_css('mark', text: 'foo!', count: 2)
    end

    it "ignores invalid backreference \\2 in substitution" do
      fill_in "regular_expression[expression]", with: '(foo)'
      fill_in "regular_expression[test_string]", with: 'foo'
      fill_in "regular_expression[substitution]", with: '\\2!'
      expect(page).to have_css('mark', text: 'foo!', count: 0)
    end
  end

  describe "Input validation" do
    before { visit root_path }

    it "shows message when both fields are empty" do
      fill_in "regular_expression[expression]", with: ''
      fill_in "regular_expression[test_string]", with: ''
      expect(page).to have_content('Railroad diagram will appear here')
      expect(page).to have_content('Regexp test result will appear here')
    end

    it "shows message when only test string is empty" do
      fill_in "regular_expression[expression]", with: 'abc'
      fill_in "regular_expression[test_string]", with: ''
      expect(page).to have_css('svg')
      expect(page).to have_content('Please enter a regex pattern and a test string.')
    end

    it "shows message when only regex pattern is empty" do
      fill_in "regular_expression[expression]", with: ''
      fill_in "regular_expression[test_string]", with: 'abc'
      expect(page).to have_content('Railroad diagram will appear here')
      expect(page).to have_content('Please enter a regex pattern and a test string.')
    end
  end

  describe "Ruby code display functionality", :js do
    before do
      visit root_path
      find('span', text: 'Try an example').click
    end

    # We do not perform detailed tests on the actual show/hide visibility of the code block,
    # because Alpine.js x-show uses complex style manipulations and transitions.
    # This makes it difficult and unreliable to detect visibility via Capybara.
    #
    # Instead, we verify that the toggle button text changes appropriately,
    # which reliably indicates that the UI interaction took place.
    it "shows and hides Ruby code block when toggling Show/Hide button" do
      toggle_button = find('button', text: 'Show')

      toggle_button.click
      expect(toggle_button).to have_text('Hide')

      toggle_button.click
      expect(toggle_button).to have_text('Show')
    end

    it "shows 'Copied!' tooltip after clicking Copy button" do
      copy_button = find('button[title="Copy Ruby Code"]')
      tooltip = find('span[data-copy-code-target="tooltip"]', visible: false)

      copy_button.click

      expect(tooltip).to have_text('Copied!')
      expect(tooltip[:class]).not_to include('invisible')
    end
  end

  describe "Regex options: Flags (i, m, x) behavior" do
    before { visit root_path }

    it "enables case-insensitive matching with 'i' option" do
      fill_in "regular_expression[expression]", with: 'foo'
      fill_in "regular_expression[test_string]", with: 'FOO'
      fill_in "regular_expression[options]", with: 'i'
      expect(page).to have_css('mark', text: 'FOO')
    end

    it "enables multiline matching with 'm' option" do
      fill_in "regular_expression[expression]", with: '^foo'
      fill_in "regular_expression[test_string]", with: "bar\nfoo"
      fill_in "regular_expression[options]", with: 'm'
      expect(page).to have_css('mark', text: 'foo')
    end

    it "enables extended mode (allow comments/spaces) with 'x' option" do
      fill_in "regular_expression[expression]", with: "f o o # match foo"
      fill_in "regular_expression[test_string]", with: 'foo'
      fill_in "regular_expression[options]", with: 'x'
      expect(page).to have_css('mark', text: 'foo')
    end

    it "enables multiple flags together" do
      fill_in "regular_expression[expression]", with: "^foo"
      fill_in "regular_expression[test_string]", with: "FOO\nfoo"
      fill_in "regular_expression[options]", with: 'im'
      expect(page).to have_css('mark', text: 'FOO')
      expect(page).to have_css('mark', text: 'foo')
    end
  end

  describe "Match result display options", :js do
    before do
      visit root_path
      page.execute_script("localStorage.clear()")
      visit current_path
    end

    it "toggles Wrap words option and checks applied CSS classes" do
      fill_in "regular_expression[expression]", with: 'foo'
      fill_in "regular_expression[test_string]", with: 'foo bar foo'

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
      fill_in "regular_expression[expression]", with: 'foo'
      fill_in "regular_expression[test_string]", with: "foo bar foo\nfoo bar foo"

      show_invisibles_checkbox = find('input[type=checkbox][x-model=showInvisibles]')
      show_invisibles_checkbox.uncheck
      expect(show_invisibles_checkbox).not_to be_checked

      expect(page).to have_content("foo bar foo\nfoo bar foo")

      show_invisibles_checkbox.check
      expect(show_invisibles_checkbox).to be_checked

      expect(page).to have_content("foo bar foo⏎\nfoo bar foo")
    end
  end

  describe 'Regular Expressions Tab Switcher' do
    before do
      visit root_path
      find('button[data-action="click->regexp-content-tab-switch#showReference"]', wait: true).click
    end

    it 'displays the correct default tab (Reference)' do
      expect(page).to have_content('Regex Quick Reference')
      expect(page).to have_css('#reference-panel')
      expect(page).to have_no_css('#examples-panel')

      expect(page).to have_button('Regex Quick Reference', class: /bg-gray-700/)
    end

    it 'switches to the Examples tab when clicked' do
      find('button[data-action="click->regexp-content-tab-switch#showExamples"]', wait: true).click

      expect(page).to have_no_css('#reference-panel')
      expect(page).to have_css('#examples-panel')

      expect(page).to have_button('Regex Examples', class: /bg-gray-700/)
      expect(page).to have_button('Regex Quick Reference', class: /bg-gray-800/)
    end

    it 'switches back to the Reference tab when clicked' do
      find('button[data-action="click->regexp-content-tab-switch#showExamples"]', wait: true).click
      find('button[data-action="click->regexp-content-tab-switch#showReference"]', wait: true).click

      expect(page).to have_css('#reference-panel')
      expect(page).to have_no_css('#examples-panel')

      expect(page).to have_button('Regex Quick Reference', class: /bg-gray-700/)
      expect(page).to have_button('Regex Examples', class: /bg-gray-800/)
    end

    context 'when viewing Regex Quick Reference content' do
      before do
        find('button[data-action="click->regexp-content-tab-switch#showReference"]', wait: true).click
      end

      it 'displays section titles and code examples correctly' do
        regex_reference_sections.each do |section|
          expect(page).to have_content(section[:title])

          section[:items].each do |code, description|
            expect(page).to have_content(code)
            expect(page).to have_content(description)

            expect(page).to have_css("code", text: code)
          end
        end
      end

      it '"Copied!" message appears when code is copied' do
        code = '[abc]'

        code_element = find('code[data-copy-code-target="source"]', text: code)
        code_element.click

        expect(page).to have_content('Copied!')
      end
    end

    context 'when viewing Regex Examples content' do
      before do
        find('button[data-action="click->regexp-content-tab-switch#showExamples"]', wait: true).click
      end

      it 'displays the example categories and allows switching between them' do
        regexp_example_categories.each_with_index do |(cat, data), i|
          expect(page).to have_css("button[data-category='#{cat.to_s.parameterize}']", text: data[:short])
        end

        first_category = regexp_example_categories.keys.first
        find("button[data-category='#{first_category.to_s.parameterize}']").click
        expect(page).to have_content(regexp_example_categories[first_category][:description])

        regexp_example_categories[first_category][:examples].each do |ex|
          expect(page).to have_content(ex[:pattern])
          expect(page).to have_content(ex[:test])
          expect(page).to have_content(ex[:description])
        end
      end

      it 'shows the correct example when clicked' do
        example = find('div[data-test="aaabc"]')
        example.click

        expect(page).to have_css('mark', text: 'aaabc')
        expect(page).to have_content('Concatenation + Repeat: \'a*\' + \'b\' + \'c\'')
      end
    end
  end

  describe "Security: Prevent HTML injection in substitution results" do
    it "escapes HTML tags in substitution result" do
      visit root_path

      fill_in "regular_expression[expression]", with: 'foo'
      fill_in "regular_expression[substitution]", with: '<script>alert(1)</script>'
      fill_in "regular_expression[test_string]", with: 'foo foo foo'

      expect(page).to have_content('Substitution result:')

      within find('h3', text: 'Substitution result:').find(:xpath, './ancestor::div[contains(@class, "mb-2")]') do
        expect(page).to have_css('mark', text: '<script>alert(1)</script>', count: 3)
      end

      within 'div.mb-2.text-left', text: 'Match result:', exact_text: false do
        expect(page).to have_css('mark', text: 'foo', count: 3)
      end
    end
  end
end
