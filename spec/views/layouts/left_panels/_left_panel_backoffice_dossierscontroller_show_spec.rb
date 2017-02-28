require 'spec_helper'

describe 'layouts/left_panels/_left_panel_backoffice_dossierscontroller_show.html.haml', type: :view do

  let!(:dossier) { create(:dossier, :with_entreprise,  state: state, archived: archived) }
  let(:state) { 'draft' }
  let(:archived) { false }
  let(:gestionnaire) { create(:gestionnaire) }

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
    context 'when dossier have state initiated' do
      let(:state) { 'initiated' }

      before do
        render
      end

      it { expect(rendered).to have_content('Nouveau') }

      it 'button Déclarer complet is present' do
        expect(rendered).to have_css('.action')
        expect(rendered).to have_content('DÉCLARER COMPLET')
      end
    end

    context 'when dossier have state replied' do
      let(:state) { 'replied' }

      before do
        render
      end

      it { expect(rendered).to have_content('En construction') }

      it 'button Déclarer complet is present' do
        expect(rendered).to have_css('.action')
        expect(rendered).to have_content('DÉCLARER COMPLET')
      end
    end

    context 'when dossier have state update' do
      let(:state) { 'updated' }

      before do
        render
      end

      it { expect(rendered).to have_content('En construction') }

      it 'button Déclarer complet is present' do
        expect(rendered).to have_css('.action')
        expect(rendered).to have_content('DÉCLARER COMPLET')
      end
    end

    context 'when dossier have state validated' do
      let(:state) { 'validated' }

      before do
        render
      end

      it { expect(rendered).to have_content('Figé') }

      it 'button Déclarer complet  is not present' do
        expect(rendered).not_to have_css('.action')
        expect(rendered).not_to have_content('Déclarer complet')
      end
    end

    context 'when dossier have state submitted' do
      let(:state) { 'submitted' }

      before do
        render
      end

      it { expect(rendered).to have_content('Déposé / À réceptionner') }

      it 'button Accuser réception is present' do
        expect(rendered).to have_css('.action')
        expect(rendered).to have_content('ACCUSER RÉCEPTION')
      end

      it 'button Déclarer complet is not present' do
        expect(rendered).not_to have_content('Accepter le dossier')
      end
    end

    context 'when dossier have state received' do
      let(:state) { 'received' }

      before do
        render
      end

      it { expect(rendered).to have_content('En instruction') }

      it 'button accepter / refuser / classer sans suite are present' do
        expect(rendered).to have_css('form[data-toggle="tooltip"][title="Accepter"]')
        expect(rendered).to have_css('form[data-toggle="tooltip"][title="Classer sans suite"]')
        expect(rendered).to have_css('form[data-toggle="tooltip"][title="Refuser"]')
      end
    end

    context 'when dossier have state closed' do
      let(:state) { 'closed' }

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