require 'spec_helper'

describe 'backoffice/index.html.haml', type: :view do
  let!(:procedure) { create(:procedure) }
  let!(:decorate_dossier) { create(:dossier, :with_user, procedure: procedure).decorate }
  before do
    assign(:dossiers_a_traiter, Dossier.a_traiter.decorate)
    assign(:dossiers_en_attente, Dossier.en_attente.decorate)
    assign(:dossiers_termine, Dossier.termine.decorate)

    decorate_dossier.submitted!
    render
  end
  subject { rendered }
  it { is_expected.to have_css('#backoffice') }
  it { is_expected.to have_content(procedure.libelle) }
  it { is_expected.to have_content(decorate_dossier.nom_projet) }
  it { is_expected.to have_content(decorate_dossier.state_fr) }
  it { is_expected.to have_content(decorate_dossier.last_update) }
end