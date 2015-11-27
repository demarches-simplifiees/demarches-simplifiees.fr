require 'spec_helper'

describe 'users/dossiers/index.html.haml', type: :view do

  describe 'list dossiers' do
    let(:user) { create(:user) }

    let!(:dossier1) { create(:dossier, :with_procedure, user: user, state: 'initiated') }
    let!(:dossier2) { create(:dossier, :with_procedure, user: user, nom_projet: 'projet de test', state: 'draft') }
    let!(:dossier3) { create(:dossier, :with_procedure, user: user, nom_projet: 'projet de test 2', state: 'initiated', archived: true) }

    let(:dossiers) { user.dossiers.where.not(state: :draft).where(archived: false).order(updated_at: 'DESC') }

    before do
      assign(:dossiers, dossiers.paginate(:page => params[:page], :per_page => 12).decorate)
      render
    end

    subject { rendered }

    it { expect(subject).to have_content(dossier1.nom_projet) }
    it { expect(subject).not_to have_content(dossier2.nom_projet) }
    it { expect(subject).not_to have_content(dossier3.nom_projet) }
  end
end