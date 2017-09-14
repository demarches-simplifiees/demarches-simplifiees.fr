require 'spec_helper'

describe 'users/description/champs/date.html.haml', type: :view do
  let(:type_champ) { create(:type_de_champ_public, type_champ: :date) }

  before do
    render 'users/description/champs/date.html.haml', champ: champ
  end

  let!(:champ) { create(:champ, type_de_champ: type_champ, value: "2017-09-19").decorate }

  it 'should render an input for the dossier link' do
    expect(rendered).to have_css("input[value='2017-09-19']")
  end
end
