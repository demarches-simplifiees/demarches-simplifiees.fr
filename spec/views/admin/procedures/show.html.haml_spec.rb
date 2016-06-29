require 'spec_helper'

describe 'admin/procedures/show.html.haml', type: :view do
  let(:archived) { false }
  let(:published) { false }
  let(:procedure) { create(:procedure, published: published, archived: archived) }

  before do
    assign(:facade, AdminProceduresShowFacades.new(procedure.decorate))
    assign(:procedure, procedure)
    render
  end

  describe 'publish button' do
    it { expect(rendered).to have_content('Publier') }
  end

  describe 'archive and unarchive button' do
    let(:published) { true }

    context 'when procedure is published' do
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
      let(:published) { true }
      it { expect(rendered).to have_content(new_users_dossiers_url(procedure_id: procedure.id)) }
    end
  end
end