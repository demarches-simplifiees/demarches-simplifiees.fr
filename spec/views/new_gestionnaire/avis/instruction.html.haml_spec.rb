describe 'new_gestionnaire/avis/instruction.html.haml', type: :view do
  let(:avis) { create(:avis, confidentiel: confidentiel) }

  before do
    assign(:avis, avis)
    @dossier = create(:dossier, :accepte)
    allow(view).to receive(:current_gestionnaire).and_return(avis.gestionnaire)
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
end
