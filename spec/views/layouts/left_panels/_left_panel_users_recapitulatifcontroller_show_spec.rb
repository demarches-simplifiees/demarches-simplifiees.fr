require 'spec_helper'

describe 'layouts/left_panels/_left_panel_users_recapitulatifcontroller_show.html.haml', type: :view do
  let(:dossier) { create(:dossier, :with_entreprise, state: state, procedure: create(:procedure, :with_api_carto, :with_two_type_de_piece_justificative, for_individual: true, individual_with_siret: true)) }
  let(:dossier_id) { dossier.id }
  let(:state) { 'draft' }

  before do
    sign_in dossier.user
    assign(:facade, DossierFacades.new(dossier.id, dossier.user.email))
  end

  context 'buttons to change dossier state' do
    context 'when dossier state is en_construction' do
      let(:state) { 'en_construction' }
      before do
        render
      end

      it { expect(rendered).to have_content('En construction') }
    end

    context 'when dossier state is closed' do
      let(:state) { 'closed' }

      before do
        render
      end
      it { expect(rendered).to have_content('Accepté') }

      it 'button Editer mon dossier n\'est plus present' do
        expect(rendered).not_to have_css('#maj_infos')
        expect(rendered).not_to have_content('Modifier mon dossier')
      end
    end

    context 'when dossier state is refused' do
      let(:state) { 'refused' }

      before do
        render
      end
      it { expect(rendered).to have_content('Refusé') }

      it 'button Editer mon dossier n\'est plus present' do
        expect(rendered).not_to have_css('#maj_infos')
        expect(rendered).not_to have_content('Modifier mon dossier')
      end
    end

    context 'when dossier state is without_continuation' do
      let(:state) { 'without_continuation' }

      before do
        render
      end
      it { expect(rendered).to have_content('Sans suite') }

      it 'button Editer mon dossier n\'est plus present' do
        expect(rendered).not_to have_css('#maj_infos')
        expect(rendered).not_to have_content('Modifier mon dossier')
      end
    end
  end
end
