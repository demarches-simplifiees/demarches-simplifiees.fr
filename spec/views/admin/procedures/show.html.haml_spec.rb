require 'spec_helper'

describe 'admin/procedures/show.html.haml', type: :view do
  let(:archived_at) { nil }
  let(:procedure) { create(:procedure, :with_service, archived_at: archived_at) }

  before do
    assign(:procedure, procedure)
  end

  describe 'procedure is draft' do
    context 'when procedure does not have a instructeur affected' do
      before do
        render
      end

      describe 'publish button is not visible' do
        it { expect(rendered).not_to have_css('a#publish-procedure') }
        it { expect(rendered).not_to have_css('button#archive-procedure') }
        it { expect(rendered).not_to have_css('a#reopen-procedure') }
      end
    end

    context 'when procedure have a instructeur affected' do
      before do
        create(:instructeur).assign_to_procedure(procedure)
        render
      end

      describe 'publish button is visible' do
        it { expect(rendered).to have_css('a#publish-procedure') }
        it { expect(rendered).not_to have_css('button#archive-procedure') }
        it { expect(rendered).not_to have_css('a#reopen-procedure') }
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
      it { expect(rendered).not_to have_css('a#publish-procedure') }
      it { expect(rendered).to have_css('button#archive-procedure') }
      it { expect(rendered).not_to have_css('a#reopen-procedure') }
    end

    describe 'procedure link is present' do
      it { expect(rendered).to have_content(commencer_url(path: procedure.path)) }
    end
  end

  describe 'procedure is archived' do
    before do
      procedure.publish!
      procedure.archive!
      procedure.reload
      render
    end

    describe 'Re-enable button is visible' do
      it { expect(rendered).not_to have_css('a#publish-procedure') }
      it { expect(rendered).not_to have_css('button#archive-procedure') }
      it { expect(rendered).to have_css('a#reopen-procedure') }
    end

    describe 'procedure link is present' do
      it { expect(rendered).to have_content('Cette démarche est archivée et n’est donc plus accessible par le public.') }
    end
  end
end
