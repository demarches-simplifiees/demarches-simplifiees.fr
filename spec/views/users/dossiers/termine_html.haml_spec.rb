require 'spec_helper'

describe 'users/dossiers/termine.html.haml', type: :view do
  let(:user) { create(:user) }

  let!(:decorate_dossier) { create(:dossier, :with_procedure, user: user, state: 'initiated', nom_projet: 'projet de test').decorate }
  let!(:decorate_dossier_2) { create(:dossier, :with_procedure, user: user, state: 'replied', nom_projet: 'projet terminé').decorate }
  let!(:dossier_termine) { create(:dossier, :with_procedure, user: user, state: 'closed').decorate }

  let(:dossiers_list) { user.dossiers.termine.paginate(:page => 1).decorate }

  before do
    assign(:dossiers, dossiers_list)
    assign(:dossiers_en_attente, dossiers_list)
    render
  end

  subject { rendered }

  it { is_expected.to have_css('#users_termine') }

  describe 'dossier termine is present' do
    it { is_expected.to have_content(dossier_termine.procedure.libelle) }
    it { is_expected.to have_content(dossier_termine.nom_projet) }
    it { is_expected.to have_content(dossier_termine.state_fr) }
    it { is_expected.to have_content(dossier_termine.last_update) }
  end

  describe 'dossier replied and initiated are not present' do
    it { is_expected.not_to have_content(decorate_dossier.nom_projet) }
    it { is_expected.not_to have_content(decorate_dossier_2.nom_projet) }
  end
end