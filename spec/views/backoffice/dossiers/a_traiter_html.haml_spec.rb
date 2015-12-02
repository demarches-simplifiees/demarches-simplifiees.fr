require 'spec_helper'

describe 'backoffice/dossiers/a_traiter.html.haml', type: :view do
  let(:administrateur) { create(:administrateur) }
  let(:gestionnaire) { create(:gestionnaire, administrateur: administrateur) }

  let!(:procedure) { create(:procedure, administrateur: administrateur) }
  let!(:decorate_dossier) { create(:dossier, :with_user, state: 'initiated', procedure: procedure).decorate }

  before do
    assign(:dossiers, gestionnaire.dossiers.waiting_for_gestionnaire.paginate(:page => 1).decorate)
    assign(:page, 'a_traiter')
    render
  end

  subject { rendered }
  it { is_expected.to have_css('#backoffice_a_traiter') }
  it { is_expected.to have_content(procedure.libelle) }
  it { is_expected.to have_content(decorate_dossier.nom_projet) }
  it { is_expected.to have_content(decorate_dossier.state_fr) }
  it { is_expected.to have_content(decorate_dossier.last_update) }

  describe 'active tab' do
    it { is_expected.to have_selector('.active .text-danger') }
  end
end