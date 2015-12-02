require 'spec_helper'

describe 'backoffice/dossiers/termine.html.haml', type: :view do
  let(:administrateur) { create(:administrateur) }
  let(:gestionnaire) { create(:gestionnaire, administrateur: administrateur) }

  let!(:procedure) { create(:procedure, administrateur: administrateur) }
  let!(:decorate_dossier) { create(:dossier, :with_user, procedure: procedure, state: 'closed').decorate }

  before do
    assign(:dossiers, gestionnaire.dossiers.termine.paginate(:page => 1).decorate)
    assign(:page, 'termine')
    render
  end

  subject { rendered }
  it { is_expected.to have_css('#backoffice_termine') }
  it { is_expected.to have_content(procedure.libelle) }
  it { is_expected.to have_content(decorate_dossier.nom_projet) }
  it { is_expected.to have_content(decorate_dossier.state_fr) }
  it { is_expected.to have_content(decorate_dossier.last_update) }

  describe 'active tab' do
    it { is_expected.to have_selector('.active .text-success') }
  end
end