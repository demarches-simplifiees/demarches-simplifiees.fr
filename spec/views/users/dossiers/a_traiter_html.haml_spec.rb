require 'spec_helper'

describe 'users/dossiers/a_traiter.html.haml', type: :view do
  let(:user) { create(:user) }

  let!(:decorate_dossier) { create(:dossier, :with_procedure, user: user, state: 'replied').decorate }
  let!(:decorate_dossier_2) { create(:dossier, :with_procedure, user: user, state: 'initiated', nom_projet: 'projet de test').decorate }

  let(:dossiers_list) { user.dossiers.waiting_for_user.paginate(:page => 1).decorate }

  before do
    assign(:dossiers, dossiers_list)
    assign(:dossiers_a_traiter, dossiers_list)
    render
  end

  subject { rendered }

  it { is_expected.to have_css('#users_a_traiter') }

  describe 'dossier replied is present' do
    it { is_expected.to have_content(decorate_dossier.procedure.libelle) }
    it { is_expected.to have_content(decorate_dossier.nom_projet) }
    it { is_expected.to have_content(decorate_dossier.state_fr) }
    it { is_expected.to have_content(decorate_dossier.last_update) }
  end

  describe 'dossier initiated is not present' do
    it { is_expected.not_to have_content(decorate_dossier_2.nom_projet) }
  end
end