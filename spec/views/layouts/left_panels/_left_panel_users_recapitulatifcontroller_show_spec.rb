require 'spec_helper'

describe 'layouts/left_panels/_left_panel_users_recapitulatifcontroller_show.html.haml', type: :view do
  let(:dossier) { create(:dossier, :with_entreprise, state: state, procedure: create(:procedure, :with_api_carto, :with_two_type_de_piece_justificative, for_individual: true, individual_with_siret: true)) }
  let(:dossier_id) { dossier.id }
  let(:state) { 'brouillon' }

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

    context 'when dossier state is accepte' do
      let(:state) { 'accepte' }

      before do
        render
      end
      it { expect(rendered).to have_content('Accepté') }

      it 'button Editer mon dossier n\'est plus present' do
        expect(rendered).not_to have_css('#maj_infos')
        expect(rendered).not_to have_content('Modifier mon dossier')
      end
    end

    context 'when dossier state is refuse' do
      let(:state) { 'refuse' }

      before do
        render
      end
      it { expect(rendered).to have_content('Refusé') }

      it 'button Editer mon dossier n\'est plus present' do
        expect(rendered).not_to have_css('#maj_infos')
        expect(rendered).not_to have_content('Modifier mon dossier')
      end
    end

    context 'when dossier state is sans_suite' do
      let(:state) { 'sans_suite' }

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
