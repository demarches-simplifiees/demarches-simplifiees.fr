require 'spec_helper'

describe 'admin/procedures/show.html.haml', type: :view do
  let(:procedure) { create(:procedure, :with_service) }

  before do
    assign(:facade, AdminProceduresShowFacades.new(procedure.decorate))
    assign(:procedure, procedure)
  end

  describe 'procedure is draft' do
    context 'when procedure does not have a gestionnare affected' do
      before do
        render
      end

      describe 'test button is not visible' do
        it { expect(rendered).to have_css('a#test-procedure[disabled]') }
        it { expect(rendered).not_to have_css('a#publish-procedure') }
        it { expect(rendered).not_to have_css('button#archive-procedure') }
        it { expect(rendered).not_to have_css('a#reopen-procedure') }
      end
    end

    context 'when procedure have a gestionnare affected' do
      before do
        create :assign_to, gestionnaire: create(:gestionnaire), procedure: procedure
        render
      end

      describe 'test button is visible' do
        it {
          expect(rendered).not_to have_css('a#test-procedure[disabled]')
          expect(rendered).to have_css('a#test-procedure')
        }
        it { expect(rendered).not_to have_css('a#publish-procedure') }
        it { expect(rendered).not_to have_css('button#archive-procedure') }
        it { expect(rendered).not_to have_css('a#reopen-procedure') }
      end

      describe 'procedure link is not present' do
        it { expect(rendered).to have_content('Cette procédure n’a pas encore été publiée et n’est donc pas accessible par le public.') }
      end
    end
  end

  describe 'procedure is testing' do
    let(:procedure) { create(:procedure, :testing) }
    before do
      render
    end

    describe 'publish button is visible' do
      it { expect(rendered).not_to have_css('a#test-procedure') }
      it { expect(rendered).to have_css('a#publish-procedure') }
      it { expect(rendered).not_to have_css('button#archive-procedure') }
      it { expect(rendered).not_to have_css('a#reopen-procedure') }
    end

    describe 'procedure link is present' do
      it { expect(rendered).to have_content(commencer_test_url(procedure_path: procedure.path)) }
    end
  end

  describe 'procedure is published' do
    let(:procedure) { create(:procedure, :published) }
    before do
      render
    end

    describe 'archive button is visible', js: true do
      it { expect(rendered).not_to have_css('a#test-procedure') }
      it { expect(rendered).not_to have_css('a#publish-procedure') }
      it { expect(rendered).to have_css('button#archive-procedure') }
      it { expect(rendered).not_to have_css('a#reopen-procedure') }
    end

    describe 'procedure link is present' do
      it { expect(rendered).to have_content(commencer_url(procedure_path: procedure.path)) }
    end
  end

  describe 'procedure is archived' do
    let(:procedure) { create(:procedure, :archived) }
    before do
      render
    end

    describe 'Re-enable button is visible' do
      it { expect(rendered).not_to have_css('a#test-procedure') }
      it { expect(rendered).not_to have_css('a#publish-procedure') }
      it { expect(rendered).not_to have_css('button#archive-procedure') }
      it { expect(rendered).to have_css('a#reopen-procedure') }
    end

    describe 'procedure link is present' do
      it { expect(rendered).to have_content('Cette procédure est archivée et n’est donc pas accessible par le public.') }
    end
  end
end
