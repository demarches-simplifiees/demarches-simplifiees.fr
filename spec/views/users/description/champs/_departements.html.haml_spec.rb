require 'spec_helper'

describe 'users/description/champs/departements.html.haml', vcr: { cassette_name: 'geoapi_departements' }, type: :view do
  let(:champ) { create(:champ) }

  before do
    render 'users/description/champs/departements.html.haml', champ: champ.decorate
  end

  it 'should render departments drop down list' do
    expect(rendered).to include("Ain")
  end
end
