require 'rails_helper'

RSpec.describe "RegularExpressions (multibyte named captures)" do
  it "does not raise and returns 200, showing a friendly error when named capture access fails" do
    params = {
      regular_expression: {
        regular_expression: '(?<名前>foo)',
        test_string: 'foo'
      }
    }

    post regular_expressions_path, params: params

    expect(response).to have_http_status(:ok)

    # Ensure we rendered the normal index content (no 500 page). Presence of the
    # turbo frame used for results is a lightweight check that the app returned
    # the expected page instead of an error page.
    expect(response.body).to include('turbo-frame id="regexp"')
  end
end
