require 'spec_helper'

describe 'backoffice/index.html.haml', type: :view do
  let(:administrateur) { create(:administrateur) }
  let(:gestionnaire) { create(:gestionnaire, administrateur: administrateur) }

  let!(:procedure) { create(:procedure, administrateur: administrateur) }
  let!(:decorate_dossier) { create(:dossier, :with_user, procedure: procedure).decorate }

  before do
    assign(:dossiers_a_traiter, Dossier.a_traiter(gestionnaire).decorate)
    assign(:dossiers_en_attente, Dossier.en_attente(gestionnaire).decorate)
    assign(:dossiers_termine, Dossier.termine(gestionnaire).decorate)

    decorate_dossier.initiated!
    render
  end

  subject { rendered }
  it { is_expected.to have_css('#backoffice') }
  it { is_expected.to have_content(procedure.libelle) }
  it { is_expected.to have_content(decorate_dossier.nom_projet) }
  it { is_expected.to have_content(decorate_dossier.state_fr) }
  it { is_expected.to have_content(decorate_dossier.last_update) }
end