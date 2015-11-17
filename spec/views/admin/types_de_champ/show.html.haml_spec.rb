require 'spec_helper'

describe 'admin/types_de_champ/show.html.haml', type: :view do
  let(:procedure) { create(:procedure) }
  let(:first_libelle) { 'salut la compagnie' }
  let(:last_libelle) { 'je suis bien sur la page' }
  let!(:type_de_champ_1) { create(:type_de_champ, procedure: procedure, order_place: 1, libelle: last_libelle) }
  let!(:type_de_champ_0) { create(:type_de_champ, procedure: procedure, order_place: 0, libelle: first_libelle) }
  before do
    procedure.reload
    assign(:procedure, procedure)
    render
  end
  it 'sorts by order place' do
    expect(rendered).to match(/#{first_libelle}.*#{last_libelle}/m)
  end
end