require 'spec_helper'

describe 'dossiers/_infos_dossier.html.haml', type: :view do
  describe "champs rendering" do
    let(:dossier) { create(:dossier, :with_entreprise, procedure: create(:procedure, :with_api_carto, :with_type_de_champ)) }

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
    end
  end

  describe "oui_non champ rendering" do
    let(:dossier_with_yes_no) { create(:dossier, procedure: create(:procedure, :with_yes_no)) }

    context "with the true value" do
      before do
        oui_non_champ = dossier_with_yes_no.champs.first
        oui_non_champ.value = 'true'
        oui_non_champ.save

        assign(:facade, DossierFacades.new(dossier_with_yes_no.id, dossier_with_yes_no.user.email))
        render
      end

      it { expect(rendered).to have_content("Oui") }
    end

    context "with the false value" do
      before do
        oui_non_champ = dossier_with_yes_no.champs.first
        oui_non_champ.value = 'false'
        oui_non_champ.save

        assign(:facade, DossierFacades.new(dossier_with_yes_no.id, dossier_with_yes_no.user.email))
        render
      end

      it { expect(rendered).to have_content("Non") }
    end

    context "with no value" do
      before do
        oui_non_champ = dossier_with_yes_no.champs.first
        oui_non_champ.value = nil
        oui_non_champ.save

        assign(:facade, DossierFacades.new(dossier_with_yes_no.id, dossier_with_yes_no.user.email))
        render
      end

      it { expect(rendered).not_to have_content("Oui") }
      it { expect(rendered).not_to have_content("Non") }
    end
  end
end
