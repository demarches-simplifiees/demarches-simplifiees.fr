require 'spec_helper'

describe 'dossiers/_infos_dossier.html.haml', type: :view do
  let(:dossier) { create(:dossier, :with_entreprise,  procedure: create(:procedure, :with_api_carto, :with_type_de_champ)) }

  before do
    champs.each do |champ|
      champ.value = ((0...8).map { (65 + rand(26)).chr }.join)
      champ.save
    end

    assign(:facade, DossierFacades.new(dossier.id, dossier.user.email))
    render
  end

  describe 'every champs are present on the page' do
    let(:champs) { dossier.champs }

    it { expect(rendered).to have_content(champs.first.libelle) }
    it { expect(rendered).to have_content(champs.first.value) }

    it { expect(rendered).to have_content(champs.last.libelle) }
    it { expect(rendered).to have_content(champs.last.value) }

    context 'when api carto is used' do
      it { expect(rendered).to have_css('#map') }
    end
  end
end
