# frozen_string_literal: true

RSpec.describe 'administrateurs/procedures/zones', type: :view do
  let(:administrateur) { administrateurs(:default_admin) }
  let(:procedure) { create(:procedure, published_at: Time.zone.parse('2022-07-20')) } # Définir une date de publication de la procédure plus tardive
  let!(:zone1) { create(:zone, acronym: 'MTEI', labels: [{ designated_on: '2022-05-18', name: "Ministère du Travail" }]) }
  let!(:zone2) { create(:zone, acronym: 'MEP', labels: [{ designated_on: '2022-05-18', name: "Ministère des vacances" }]) }

  before do
    allow(view).to receive(:current_administrateur).and_return(administrateur)
    assign(:procedure, procedure)
    assign(:zones, Zone.available_at(procedure.published_or_created_at, administrateur.default_zones))
  end

  it 'affiche le titre de la page' do
    render
    expect(rendered).to include('Zones')
  end

  it 'affiche les zones par défaut de l’administrateur' do
    allow(administrateur).to receive(:default_zones).and_return([zone1])
    assign(:zones, Zone.available_at(procedure.published_or_created_at, administrateur.default_zones))
    render

    expect(rendered).to match(/Ministère du Travail/)
  end

  it 'affiche toutes les zones disponibles' do
    render

    expect(rendered).to match(/Ministère du Travail/)
    expect(rendered).to match(/Ministère des vacances/)
  end

  it 'affiche les actions en bas de page' do
    render

    expect(rendered).to include('Annuler')
    expect(rendered).to include('Enregistrer')
  end

  context 'quand le zonage est désactivé' do
    before { allow(Rails.application.config).to receive(:ds_zonage_enabled).and_return(false) }

    it 'n’affiche pas les zones' do
      render

      expect(rendered).not_to match(/Ministère du Travail/)
      expect(rendered).not_to match(/Ministère des vacances/)
    end
  end
end
