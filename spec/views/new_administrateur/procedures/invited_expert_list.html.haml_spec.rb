describe 'new_administrateur/procedures/invited_expert_list.html.haml', type: :view do
  let!(:procedure) { create(:procedure, :published) }

  before do
    assign(:procedure, procedure)
    assign(:procedure_lien, commencer_url(path: procedure.path))
    allow(view).to receive(:current_administrateur).and_return(procedure.administrateurs.first)
  end

  subject { render }

  context 'when the procedure has 0 avis' do
    let!(:dossier) { create(:dossier, procedure: procedure) }
    before do
      @invited_expert_emails = Avis.invited_expert_emails(procedure)
      subject
    end

    it 'has 0 experts into the page' do
      expect(@invited_expert_emails.count).to eq(0)
      expect(@invited_expert_emails).to eq([])
    end
  end

  context 'when the procedure has 3 avis from 2 experts and 1 unasigned' do
    let!(:dossier) { create(:dossier, procedure: procedure) }
    let!(:avis) { create(:avis, dossier: dossier, instructeur: create(:instructeur, email: '1_expert@expert.com')) }
    let!(:avis2) { create(:avis, dossier: dossier, instructeur: create(:instructeur, email: '2_expert@expert.com')) }
    let!(:unasigned_avis) { create(:avis, dossier: dossier, email: 'expert@expert.com') }

    before do
      @invited_expert_emails = Avis.invited_expert_emails(procedure)
      subject
    end

    it 'has 3 experts and match array' do
      expect(@invited_expert_emails.count).to eq(3)
      expect(@invited_expert_emails).to eq(['1_expert@expert.com', '2_expert@expert.com', 'expert@expert.com'])
    end
  end
end
