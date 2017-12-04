require 'spec_helper'

describe 'layouts/left_panels/_left_panel_backoffice_dossierscontroller_show.html.haml', type: :view do
  let!(:dossier) { create(:dossier, :with_entreprise,  state: state, archived: archived) }
  let(:state) { 'brouillon' }
  let(:archived) { false }
  let(:gestionnaire) { create(:gestionnaire) }
  let!(:assign_to) { create(:assign_to, gestionnaire: gestionnaire, procedure: dossier.procedure) }

  before do
    sign_in gestionnaire
    assign(:facade, (DossierFacades.new dossier.id, gestionnaire.email))

    @request.env['PATH_INFO'] = 'backoffice/user'

    render
  end

  subject { rendered }

  it 'dossier number is present' do
    expect(rendered).to have_selector('#dossier_id')
    expect(rendered).to have_content(dossier.id)
  end

  context 'button dossier state changements' do
    shared_examples 'button Passer en instruction is present' do
      it { expect(rendered).to have_link('Passer en instruction') }
    end

    context 'when dossier have state en_construction' do
      let(:state) { 'en_construction' }

      before do
        render
      end

      it { expect(rendered).to have_content('En construction') }

      include_examples 'button Passer en instruction is present'
    end

    context 'when dossier have state en_instruction' do
      let(:state) { 'en_instruction' }

      before do
        render
      end

      it { expect(rendered).to have_content('En instruction') }

      it 'button accepter / refuser / classer sans suite are present' do
        expect(rendered).to have_css('button[title="Accepter"]')
        expect(rendered).to have_css('button[title="Classer sans suite"]')
        expect(rendered).to have_css('button[title="Refuser"]')
      end
    end

    context 'when dossier have state accepte' do
      let(:state) { 'accepte' }

      before do
        render
      end

      it { expect(rendered).to have_content('Accepté') }

      it 'button Accepter le dossier is not present' do
        expect(rendered).not_to have_css('form[data-toggle="tooltip"][title="Accepter"]')
        expect(rendered).not_to have_css('form[data-toggle="tooltip"][title="Classer sans suite"]')
        expect(rendered).not_to have_css('form[data-toggle="tooltip"][title="Refuser"]')
      end
    end

    context 'when dossier have state without_continuation' do
      let(:state) { 'without_continuation' }

      before do
        render
      end

      it { expect(rendered).to have_content('Sans suite') }

      it 'button Déclarer complet is not present' do
        expect(rendered).not_to have_css('form[data-toggle="tooltip"][title="Accepter"]')
        expect(rendered).not_to have_css('form[data-toggle="tooltip"][title="Classer sans suite"]')
        expect(rendered).not_to have_css('form[data-toggle="tooltip"][title="Refuser"]')
      end
    end

    context 'when dossier have state refused' do
      let(:state) { 'refused' }

      before do
        render
      end

      it { expect(rendered).to have_content('Refusé') }

      it 'button Déclarer complet is not present' do
        expect(rendered).not_to have_css('form[data-toggle="tooltip"][title="Accepter"]')
        expect(rendered).not_to have_css('form[data-toggle="tooltip"][title="Classer sans suite"]')
        expect(rendered).not_to have_css('form[data-toggle="tooltip"][title="Refuser"]')
      end
    end

    context 'when dossier is not archived' do
      let(:archived) { false }

      before do
        render
      end

      it { expect(rendered).to have_link('Archiver') }
    end

    context 'when dossier is archived' do
      let(:archived) { true }

      before do
        render
      end

      it { expect(rendered).to have_content('Archivé') }
      it { expect(rendered).to have_link('Désarchiver') }
    end
  end
end
