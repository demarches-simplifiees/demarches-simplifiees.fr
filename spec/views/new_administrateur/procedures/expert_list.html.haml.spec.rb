describe 'new_administrateur/procedures/expert_list.html.haml', type: :view do
  let(:claimant) { create(:instructeur) }
  let(:instructeur) { create(:instructeur) }
  let(:instructeur2) { create(:instructeur) }
  let(:procedure) { create(:procedure, :published, instructeurs: [claimant]) }
  let(:dossier) { create(:dossier, :en_construction, procedure: procedure) }
  let!(:avis_with_answer) { Avis.create(dossier: dossier, claimant: claimant, instructeur: instructeur, answer: 'yop') }
  let!(:avis_with_answer2) { Avis.create(dossier: dossier, claimant: claimant, instructeur: instructeur, answer: 'yop') }
  let!(:avis_with_answer3) { Avis.create(dossier: dossier, claimant: claimant, instructeur: instructeur2, answer: 'yop') }

  before do
    assign(:procedure, procedure)
    assign(:procedure_lien, commencer_url(path: procedure.path))
    allow(view).to receive(:current_administrateur).and_return(procedure.administrateurs.first)
  end

  def expert_list
    if procedure.allow_expert_review?
      expert_emails = Avis
        .joins(dossier: :procedure)
        .left_joins(instructeur: :user)
        .where(dossiers: { revision: procedure.revisions })
        .map(&:email_to_display)
        .uniq
    end
  end

  context 'when allow expert review is true' do
    before do
      expert_list
      render
    end

    it 'has 2 experts' do
      puts expert_list
      expect(expert_list.count).to eq(2)
    end
  end

  context 'when allow expert review is false' do
    before do
      procedure.update!(allow_expert_review: false)
      procedure.reload
      expert_list
      render
    end

    it 'has 0 experts' do
      puts expert_list
      expect(expert_list).to eq(nil)
    end
  end
end
