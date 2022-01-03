describe 'experts/avis/index.html.haml', type: :view do
  let!(:expert) { create(:expert) }
  let!(:claimant) { create(:instructeur) }
  let!(:procedure) { create(:procedure) }
  let!(:avis) { create(:avis, claimant: claimant, experts_procedure: experts_procedure) }
  let!(:experts_procedure) { create(:experts_procedure, expert: expert, procedure: procedure) }

  before do
    allow(view).to receive(:current_expert).and_return(avis.expert)
    assign(:dossier, avis.dossier)
    allow(view).to receive(:current_expert).and_return(avis.expert)
  end

  subject { render }

  context 'when the dossier is deleted by instructeur' do
    before do
      avis.dossier.update!(state: "accepte", hidden_by_administration_at: Time.zone.now.beginning_of_day.utc)
      assign(:avis_by_procedure, avis.expert.avis.includes(dossier: [groupe_instructeur: :procedure]).where(dossiers: { hidden_by_administration_at: nil }).to_a.group_by(&:procedure))
    end
    it { is_expected.not_to have_text("avis à donner") }
  end

  context 'when the dossier is not deleted by instructeur' do
    before do
      assign(:avis_by_procedure, avis.expert.avis.includes(dossier: [groupe_instructeur: :procedure]).where(dossiers: { hidden_by_administration_at: nil }).to_a.group_by(&:procedure))
    end
    it { is_expected.to have_text("avis à donner") }
  end
end
