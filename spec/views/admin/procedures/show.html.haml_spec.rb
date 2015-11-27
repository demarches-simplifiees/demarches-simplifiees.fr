require 'spec_helper'

describe 'admin/procedures/show.html.haml', type: :view do
  describe 'archive and unarchive button' do

    before do
      assign(:procedure, procedure)
      render
    end

    context 'when procedure is active' do
      let(:procedure) { create(:procedure) }

      it { expect(rendered).to have_content('Archiver') }
    end

    context 'when procedure is archived' do
      let(:procedure) { create(:procedure, archived: true) }

      it { expect(rendered).to have_content('Activer') }
    end
  end
end