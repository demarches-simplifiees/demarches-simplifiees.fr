require 'spec_helper'

describe 'users/dossiers/index.html.haml', type: :view do

  describe 'list dossiers' do
    let(:dossier1) { create(:dossier).decorate }
    let(:dossier2) { create(:dossier).decorate }
    before do
      assign(:dossiers, [dossier1, dossier2])
      render
    end
    subject { rendered }
    it { expect(subject).to have_content(dossier1.nom_projet) }
  end

end