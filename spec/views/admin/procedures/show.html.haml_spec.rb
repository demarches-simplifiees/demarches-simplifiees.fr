require 'spec_helper'

describe 'admin/procedures/show.html.haml', type: :view do
  let(:archived) { false }
  let(:procedure) { create(:procedure, archived: archived) }

  before do
    assign(:facade, AdminProceduresShowFacades.new(procedure.decorate))
    assign(:procedure, procedure)
    render
  end

  describe 'publish button' do
    it { expect(rendered).to have_content('Publier') }
  end

  describe 'archive and unarchive button' do
    before do
      procedure.publish('fake_path')
      render
    end

    context 'when procedure is published' do
      before do
        procedure.publish('fake_path')
        procedure.reload
      end
      it { expect(rendered).to have_content('Archiver') }
    end

    context 'when procedure is archived' do
      let(:archived) { true }
      it { expect(rendered).to have_content('Réactiver') }
    end
  end

  describe 'procedure link' do

    context 'is not present when not published' do
      it { expect(rendered).to have_content('Cette procédure n\'a pas encore été publiée et n\'est donc pas accessible par le public.') }
    end

    context 'is present when already published' do
      before do
        procedure.publish('fake_path')
        render
      end
      it { expect(rendered).to have_content(commencer_url(procedure_path: procedure.path)) }
    end

    context 'is not present when archived' do
      before do
        procedure.archive
        render
      end
      it { expect(rendered).to have_content('Cette procédure a été archivée et n\'est plus accessible par le public.') }
    end
  end
end