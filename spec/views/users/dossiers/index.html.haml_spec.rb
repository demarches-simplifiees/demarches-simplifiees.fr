require 'spec_helper'

describe 'users/dossiers/index.html.haml', type: :view do

  describe 'list dossiers' do
    let(:user) { create(:user) }

    let!(:dossier1) { create(:dossier, user: user, state: 'initiated') }
    let!(:dossier2) { create(:dossier, user: user, state: 'initiated') }
    let(:dossiers) { user.dossiers.where("state NOT IN ('draft')").order(updated_at: 'DESC') }


    before do
      assign(:dossiers, dossiers.paginate(:page => params[:page], :per_page => 12).decorate)
      render
    end
    subject { rendered }
    it { expect(subject).to have_content(dossier1.nom_projet) }
  end
end