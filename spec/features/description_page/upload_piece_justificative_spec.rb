require 'spec_helper'

feature 'user is on description page' do
  let!(:procedure) { create(:procedure, :with_two_type_de_piece_justificative, :with_type_de_champ) }
  let!(:dossier) { create(:dossier, :with_entreprise, procedure: procedure, autorisation_donnees: true) }

  before do
    allow(ClamavService).to receive(:safe_file?).and_return(true)

    visit users_dossier_description_path dossier

    within('#new_user') do
      page.find_by_id('user_email').set dossier.user.email
      page.find_by_id('user_password').set dossier.user.password
      page.click_on 'Se connecter'
    end
  end

  it { expect(page).to have_css('#description-page') }

  context 'he fill description fields' do
    before do
      find_by_id("champs_#{dossier.champs.first.id}").set 'mon nom'
    end
    context 'before submit' do
      it 'pieces_justificatives are empty' do
        dossier.pieces_justificatives.each do |piece_justificative|
          expect(piece_justificative).to be_empty
        end
      end
    end
    context 'when he adds a piece_justificative and submit form', vcr: { cassette_name: 'description_page_upload_piece_justificative_adds_cerfa_and_submit' } do
      before do
        file_input_id = "piece_justificative_#{dossier.types_de_piece_justificative.first.id.to_s}"
        attach_file(file_input_id, File.path('spec/support/files/dossierPDF.pdf'))
        click_on('Soumettre mon dossier')
        dossier.reload
      end
      scenario 'fills the given piece_justificative' do
        expect(dossier.pieces_justificatives.first).not_to be_empty
      end
    end
  end
end
