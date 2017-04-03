require 'spec_helper'

describe 'users/description/champs/pays.html.haml', type: :view do
  let(:champ) { create(:champ) }

  before do
    render 'users/description/champs/pays.html.haml', champ: champ.decorate
  end

  it 'should render pays drop down list' do
    expect(rendered).to include("FRANCE")
  end
end
