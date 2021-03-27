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
      @invited_experts = procedure.experts_procedures
      subject
    end

    it 'has 0 experts into the page' do
      expect(@invited_experts.count).to eq(0)
      expect(@invited_experts).to eq([])
    end
  end

  context 'when the procedure has 3 avis from 2 experts and 1 unasigned' do
    let!(:dossier) { create(:dossier, procedure: procedure) }
    let!(:avis) { create(:avis, dossier: dossier) }
    let!(:avis2) { create(:avis, dossier: dossier) }

    before do
      @invited_experts = procedure.experts_procedures
      subject
    end

    it 'has 2 experts and match array' do
      expect(@invited_experts.count).to eq(2)
      expect(@invited_experts).to match_array([avis.experts_procedure, avis2.experts_procedure])
    end
  end
end
