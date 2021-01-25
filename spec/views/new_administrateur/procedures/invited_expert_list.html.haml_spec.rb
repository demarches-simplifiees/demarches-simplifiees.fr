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
      @invited_expert_emails = ExpertsProcedure.invited_expert_emails(procedure)
      subject
    end

    it 'has 0 experts into the page' do
      expect(@invited_expert_emails.count).to eq(0)
      expect(@invited_expert_emails).to eq([])
    end
  end

  context 'when the procedure has 3 avis from 2 experts and 1 unasigned' do
    let!(:dossier) { create(:dossier, procedure: procedure) }
    let(:expert) { create(:expert) }
    let(:expert2) { create(:expert) }
    let(:experts_procedure) { ExpertsProcedure.create(procedure: procedure, expert: expert) }
    let(:experts_procedure2) { ExpertsProcedure.create(procedure: procedure, expert: expert2) }
    let!(:avis) { create(:avis, dossier: dossier, experts_procedure: experts_procedure) }
    let!(:avis2) { create(:avis, dossier: dossier, experts_procedure: experts_procedure2) }

    before do
      @invited_expert_emails = ExpertsProcedure.invited_expert_emails(procedure)
      subject
    end

    it 'has 2 experts and match array' do
      expect(@invited_expert_emails.count).to eq(2)
      expect(@invited_expert_emails).to eq([expert.email, expert2.email])
    end
  end
end
