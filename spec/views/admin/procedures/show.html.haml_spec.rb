require 'spec_helper'

describe 'admin/procedures/show.html.haml', type: :view do
  let(:archived) { false }
  let(:procedure) { create(:procedure, archived: archived) }

  before do
    assign(:facade, AdminProceduresShowFacades.new(procedure.decorate))
    assign(:procedure, procedure)
  end

  describe 'procedure is draft' do
    before do
      render
    end

    describe 'publish button is visible' do
      it { expect(rendered).to have_css('a#publish') }
      it { expect(rendered).not_to have_css('button#archive') }
      it { expect(rendered).not_to have_css('a#reenable') }
    end

    describe 'procedure link is not present' do
      it { expect(rendered).to have_content('Cette procédure n\'a pas encore été publiée et n\'est donc pas accessible par le public.') }
    end
  end

  describe 'procedure is published' do
    before do
      procedure.publish!('fake_path')
      procedure.reload
      render
    end

    describe 'archive button is visible', js: true do
      it { expect(rendered).not_to have_css('a#publish') }
      it { expect(rendered).to have_css('button#archive') }
      it { expect(rendered).not_to have_css('a#reenable') }
    end

    describe 'procedure link is present' do
      it { expect(rendered).to have_content(commencer_url(procedure_path: procedure.path)) }
    end
  end

  describe 'procedure is archived' do
    before do
      procedure.publish!('fake_path')
      procedure.archive
      procedure.reload
      render
    end

    describe 'Re-enable button is visible' do
      it { expect(rendered).not_to have_css('a#publish') }
      it { expect(rendered).not_to have_css('button#archive') }
      it { expect(rendered).to have_css('a#reenable') }
    end

    describe 'procedure link is not present' do
      it { expect(rendered).to have_content('Cette procédure a été archivée et n\'est plus accessible par le public.') }
    end
  end

end