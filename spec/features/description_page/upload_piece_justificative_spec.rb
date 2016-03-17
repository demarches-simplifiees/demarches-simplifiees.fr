require 'spec_helper'

feature 'user is on description page' do
  let!(:procedure) { create(:procedure, :with_two_type_de_piece_justificative, cerfa_flag: true) }
  let!(:dossier) { create(:dossier, :with_entreprise, procedure: procedure) }
  before do
    visit users_dossier_description_path dossier

    within('#new_user') do
      page.find_by_id('user_email').set dossier.user.email
      page.find_by_id('user_password').set dossier.user.password
      page.click_on 'Se connecter'
    end

  end
  it { expect(page).to have_css('#description_page') }

  context 'he fill description fields' do
    before do
      find_by_id('nom_projet').set 'mon nom'
      find_by_id('description').set 'ma description'
    end
    context 'before submit' do
      it 'dossier cerfa is empty' do
        expect(dossier.cerfa).to be_empty
      end
      it 'pieces_justificatives are empty' do
        dossier.pieces_justificatives.each do |piece_justificative|
          expect(piece_justificative).to be_empty
        end
      end
    end
    context 'he adds cerfa' do
      before do
        attach_file('cerfa_pdf', File.path('spec/support/files/dossierPDF.pdf'))
        click_on("Soumettre mon dossier")
        dossier.reload
      end
      it 'fills dossier cerfa' do
        expect(dossier.cerfa).not_to be_empty
      end
    end
    context 'when he adds a piece_justificative and submit form' do
      before do
        file_input_id = 'piece_justificative_' + dossier.types_de_piece_justificative.first.id.to_s
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