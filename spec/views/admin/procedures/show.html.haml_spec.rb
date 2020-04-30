describe 'admin/procedures/show.html.haml', type: :view do
  let(:closed_at) { nil }
  let(:procedure) { create(:procedure, :with_service, closed_at: closed_at) }

  before do
    assign(:procedure, procedure)
    assign(:procedure_lien, commencer_url(path: procedure.path))
  end

  describe 'procedure is draft' do
    context 'when procedure does not have a instructeur affected' do
      before do
        render
      end

      describe 'publish button is not visible' do
        it { expect(rendered).not_to have_css('button#publish-procedure') }
        it { expect(rendered).not_to have_css('button#archive-procedure') }
        it { expect(rendered).not_to have_css('button#reopen-procedure') }
      end
    end

    context 'when procedure have a instructeur affected' do
      before do
        create(:instructeur).assign_to_procedure(procedure)
        render
      end

      describe 'publish button is visible' do
        it { expect(rendered).to have_css('button#publish-procedure') }
        it { expect(rendered).not_to have_css('button#archive-procedure') }
        it { expect(rendered).not_to have_css('button#reopen-procedure') }
      end

      describe 'procedure path is not customized' do
        it { expect(rendered).to have_content('Cette démarche est actuellement en test') }
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
      it { expect(rendered).not_to have_css('button#publish-procedure') }
      it { expect(rendered).to have_css('button#archive-procedure') }
      it { expect(rendered).not_to have_css('button#reopen-procedure') }
    end

    describe 'procedure link is present' do
      it { expect(rendered).to have_content(commencer_url(path: procedure.path)) }
    end
  end

  describe 'procedure is closed' do
    before do
      procedure.publish!
      procedure.close!
      procedure.reload
      render
    end

    describe 'Re-enable button is visible' do
      it { expect(rendered).not_to have_css('button#publish-procedure') }
      it { expect(rendered).not_to have_css('button#archive-procedure') }
      it { expect(rendered).to have_css('button#reopen-procedure') }
    end

    describe 'procedure link is present' do
      it { expect(rendered).to have_content('Cette démarche est close et n’est donc plus accessible par le public.') }
    end
  end
end
