require 'spec_helper'

describe 'admin/procedures/show.html.haml', type: :view do
  let(:procedure) { create(:procedure) }

  before do
    assign(:procedure, procedure.decorate)
    assign(:facade, AdminProceduresShowFacades.new(procedure))

    render
  end

  describe 'archive and unarchive button' do
    context 'when procedure is active' do
      it { expect(rendered).to have_content('Archiver') }
    end

    context 'when procedure is archived' do
      let(:procedure) { create(:procedure, archived: true) }

      it { expect(rendered).to have_content('Réactiver') }
    end
  end

  describe 'procedure link is present' do
    it { expect(rendered).to have_content(new_users_dossiers_url(procedure_id: procedure.id)) }
  end
end