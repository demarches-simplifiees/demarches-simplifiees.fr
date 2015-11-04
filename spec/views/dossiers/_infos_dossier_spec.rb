require 'spec_helper'

describe 'dossiers/_infos_dossier.html.haml', type: :view do
  let(:dossier) { create(:dossier, :with_entreprise, :with_procedure, :with_user) }

  before do
    assign(:dossier, dossier.decorate)
    assign(:champs, dossier.ordered_champs)
    assign(:procedure, dossier.procedure)
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
