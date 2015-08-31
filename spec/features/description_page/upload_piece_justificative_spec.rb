require 'spec_helper'

feature 'user is on description page' do
  let(:dossier) { create(:dossier, :with_entreprise) }
  before do
    visit dossier_description_path dossier
  end
  it { expect(page).to have_css('#description_page') }

  context 'he fill description fields' do
    before do
      find_by_id('nom_projet').set 'mon nom'
      find_by_id('description').set 'ma description'
      find_by_id('montant_projet').set 10_000
      find_by_id('montant_aide_demande').set 100
      find_by_id('date_previsionnelle').set '10/10/2010'
      find_by_id('mail_contact').set 'plop@plop.com'
    end
    context 'before submit' do
      it 'dossier cerfa is empty' do
        expect(dossier.cerfa).to be_empty
      end
      it 'pieces_jointes are empty' do
        dossier.pieces_jointes.each do |piece_jointe|
          expect(piece_jointe).to be_empty
        end
      end
    end
    context 'he adds cerfa' do
      before do
        attach_file('cerfa_pdf', File.path('spec/support/files/dossierPDF.pdf'))
        click_on("Terminer la procédure")
        dossier.reload
      end
      it 'fills dossier cerfa' do
        expect(dossier.cerfa).not_to be_empty
      end
    end
    context 'when he adds a piece_jointe and submit form' do
      before do
        file_input_id = 'piece_jointe_' + dossier.pieces_jointes.first.type.to_s
        attach_file(file_input_id, File.path('spec/support/files/dossierPDF.pdf'))
        click_on('Terminer la procédure')
        dossier.reload
      end
      scenario 'fills the given piece_jointe' do
        expect(dossier.pieces_jointes.first).not_to be_empty
      end
    end
  end
end