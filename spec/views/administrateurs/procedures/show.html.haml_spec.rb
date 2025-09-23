# frozen_string_literal: true

describe 'administrateurs/procedures/show', type: :view do
  let(:closed_at) { nil }
  let(:procedure) { create(:procedure, :with_service, closed_at: closed_at, types_de_champ_public: [{ type: :yes_no }]) }

  before do
    assign(:procedure, procedure)
    assign(:procedure_lien, commencer_url(path: procedure.path))
    assign(:procedure_lien_test, commencer_test_url(path: procedure.path))
    allow(view).to receive(:current_administrateur).and_return(procedure.administrateurs.first)
  end

  describe 'procedure is draft' do
    context 'when procedure have a instructeur affected' do
      before do
        create(:instructeur).assign_to_procedure(procedure)
        render
      end

      it "renders content" do
        expect(rendered).to have_css('#publish-procedure-link')
        expect(rendered).not_to have_css('#close-procedure-link')
        expect(rendered).to have_content('En test')
        expect(rendered).not_to have_css('#archive-procedure')
        expect(rendered).to have_css('#delete-procedure')
        expect(rendered).to have_css('#clone-procedure')
        expect(rendered).to have_css('#preview-procedure')
      end
    end
  end

  describe 'procedure is published' do
    before do
      procedure.publish!(procedure.administrateurs.first)
      procedure.reload
      render
    end

    it "renders content" do
      expect(rendered).not_to have_css('#publish-procedure-link')
      expect(rendered).to have_css('#close-procedure-link')
      expect(rendered).to have_css('#archive-procedure')
      expect(rendered).not_to have_css('#delete-procedure')
      expect(rendered).to have_css('#clone-procedure')
      expect(rendered).to have_css('#preview-procedure')
    end
  end

  describe 'procedure is closed' do
    before do
      procedure.publish!(procedure.administrateurs.first)
      procedure.close!
      procedure.reload
      render
    end

    it "renders content" do
      expect(rendered).not_to have_css('#close-procedure-link')
      expect(rendered).to have_css('#publish-procedure-link')
      expect(rendered).to have_content('Réactiver')
      expect(rendered).to have_css('#delete-procedure')
      expect(rendered).to have_css('#clone-procedure')
      expect(rendered).to have_css('#preview-procedure')
    end
  end

  describe 'procedure with expiration disabled' do
    let(:procedure) { create(:procedure, procedure_expires_when_termine_enabled: true) }
    before do
      render
    end
    it 'does not render partial to enable procedure_expires_when_termine_enabled' do
      expect(rendered).not_to have_css("div[data-test-suggest_expires_when_termine]")
    end
  end

  describe 'procedure with expiration enabled' do
    let(:procedure) { create(:procedure, procedure_expires_when_termine_enabled: false) }
    before do
      render
    end
    it 'renders a partial to enable procedure_expires_when_termine_enabled' do
      expect(rendered).to have_css("div[data-test-suggest_expires_when_termine]")
    end
  end
end
