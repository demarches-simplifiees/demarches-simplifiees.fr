describe 'instructeurs/avis/instruction.html.haml', type: :view do
  let(:expert) { create(:instructeur) }
  let(:avis) { create(:avis, confidentiel: confidentiel, email: expert.email) }

  before do
    assign(:avis, avis)
    assign(:new_avis, Avis.new)
    assign(:dossier, avis.dossier)
    allow(view).to receive(:current_instructeur).and_return(avis.instructeur)
  end

  subject { render }

  context 'with a confidential avis' do
    let(:confidentiel) { true }
    it { is_expected.to have_text("Cet avis est confidentiel et n'est pas affiché aux autres experts consultés") }
  end

  context 'with a not confidential avis' do
    let(:confidentiel) { false }
    it { is_expected.to have_text("Cet avis est partagé avec les autres experts") }
  end

  context 'when an expert is not allowed to invite another expert' do
    let(:confidentiel) { false }
    before do
      Flipper.enable_actor(:expert_not_allowed_to_invite, avis.procedure)
    end
    it { is_expected.to have_no_text("Inviter des personnes à donner leur avis") }
  end
end
