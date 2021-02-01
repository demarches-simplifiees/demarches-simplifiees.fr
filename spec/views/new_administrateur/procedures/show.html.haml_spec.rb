describe 'new_administrateur/procedures/show.html.haml', type: :view do
  let(:closed_at) { nil }
  let(:procedure) { create(:procedure, :with_service, closed_at: closed_at) }

  before do
    assign(:procedure, procedure)
    assign(:procedure_lien, commencer_url(path: procedure.path))
    allow(view).to receive(:current_administrateur).and_return(procedure.administrateurs.first)
  end

  describe 'procedure is draft' do
    context 'when procedure have a instructeur affected' do
      before do
        create(:instructeur).assign_to_procedure(procedure)
        render
      end

      describe 'publish button is visible' do
        it { expect(rendered).to have_css('#publish-procedure-link') }
        it { expect(rendered).not_to have_css('#close-procedure-link') }
      end

      describe 'procedure path is not customized' do
        it { expect(rendered).to have_content('Brouillon') }
      end
    end
  end

  describe 'procedure is published' do
    before do
      procedure.publish!
      procedure.reload
      render
    end

    describe 'archive button is visible', js: true do
      it { expect(rendered).not_to have_css('#publish-procedure-link') }
      it { expect(rendered).to have_css('#close-procedure-link') }
    end
  end

  describe 'procedure is closed' do
    before do
      procedure.publish!
      procedure.close!
      procedure.reload
    end

    describe 'Re-enable button is visible' do
      before do
        render
      end

      it { expect(rendered).not_to have_css('#close-procedure-link') }
      it { expect(rendered).to have_css('#publish-procedure-link') }
      it { expect(rendered).to have_content('Réactiver') }
    end

    describe 'When procedure.allow_expert_review is true, the expert list card must be visible' do
      before do
        render
      end
      it { expect(procedure.allow_expert_review).to be_truthy }
      it { expect(rendered).to have_content('Liste des experts invités par les instructeurs') }
    end

    describe 'When procedure.allow_expert_review is false, the expert list card must not be visible' do
      before do
        procedure.update!(allow_expert_review: false)
        procedure.reload
        render
      end

      it { expect(procedure.allow_expert_review).to be_falsy }
      it { expect(rendered).not_to have_content('Liste des experts invités par les instructeurs') }
    end
  end
end
