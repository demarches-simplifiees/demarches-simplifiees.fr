describe 'experts/avis/instruction.html.haml', type: :view do
  let(:expert) { create(:expert) }
  let(:claimant) { create(:instructeur) }
  let(:procedure) { create(:procedure) }
  let(:experts_procedure) { create(:experts_procedure, expert: expert, procedure: procedure) }
  let(:avis) { create(:avis, confidentiel: confidentiel, claimant: claimant, experts_procedure: experts_procedure) }

  before do
    assign(:avis, avis)
    assign(:new_avis, Avis.new)
    assign(:dossier, avis.dossier)
    allow(view).to receive(:current_expert).and_return(avis.expert)
  end

  subject { render }

  context 'with a confidential avis' do
    let(:confidentiel) { true }
    it { is_expected.to have_text("Cet avis est confidentiel et n’est pas affiché aux autres experts consultés") }
  end

  context 'with a not confidential avis' do
    let(:confidentiel) { false }
    it { is_expected.to have_text("Cet avis est partagé avec les autres experts") }
  end
end
