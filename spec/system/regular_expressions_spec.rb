require 'rails_helper'

RSpec.describe "RegularExpressions" do
  it 'example link' do
    visit '/'
    expect(page).to have_content('Rubree')
    find('span', text: 'Try an example').click
    expect(page).to have_content('Today\'s date is')
  end
end
