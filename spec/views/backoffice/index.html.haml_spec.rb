require 'spec_helper'

describe 'backoffice/index.html.haml', type: :view do
  before do
    render
  end
  it { expect(rendered).to have_css('#backoffice') }

end