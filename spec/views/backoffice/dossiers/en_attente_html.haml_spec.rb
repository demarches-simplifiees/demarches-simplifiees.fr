require 'spec_helper'

describe 'backoffice/dossiers/en_attente.html.haml', type: :view do
  let(:administrateur) { create(:administrateur) }
  let(:gestionnaire) { create(:gestionnaire, administrateur: administrateur) }

  let!(:procedure) { create(:procedure, administrateur: administrateur) }
  let!(:decorate_dossier) { create(:dossier, :with_user, procedure: procedure, state: 'replied').decorate }

  before do
    assign(:dossiers_en_attente, Dossier.en_attente(gestionnaire).decorate)
    render
  end

  subject { rendered }
  it { is_expected.to have_css('#backoffice_en_attente') }
  it { is_expected.to have_content(procedure.libelle) }
  it { is_expected.to have_content(decorate_dossier.nom_projet) }
  it { is_expected.to have_content(decorate_dossier.state_fr) }
  it { is_expected.to have_content(decorate_dossier.last_update) }
end