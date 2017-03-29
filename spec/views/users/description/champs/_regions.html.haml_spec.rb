require 'spec_helper'

describe 'users/description/champs/regions.html.haml', vcr: {cassette_name: 'geoapi_regions'}, type: :view do
  let(:champ) { create(:champ) }

  before do
    render 'users/description/champs/regions.html.haml', champ: champ.decorate
  end

  it 'should render regions drop down list' do
    expect(rendered).to include("Normandie")
  end
end
