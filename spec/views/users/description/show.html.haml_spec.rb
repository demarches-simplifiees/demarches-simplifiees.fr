require 'spec_helper'

describe 'users/description/show.html.haml', type: :view do
  let(:user) { create(:user) }
  let(:cerfa_flag) { true }
  let(:procedure) { create(:procedure, :with_two_type_de_piece_justificative, :with_type_de_champ, :with_datetime, cerfa_flag: cerfa_flag) }
  let(:dossier) { create(:dossier, procedure: procedure, user: user) }
  let(:dossier_id) { dossier.id }

  before do
    sign_in user
    assign(:dossier, dossier)
    assign(:procedure, dossier.procedure)
    assign(:champs, dossier.ordered_champs)
  end

  context 'tous les attributs sont présents sur la page' do
    before do
      render
    end
    it 'Le formulaire envoie vers /users/dossiers/:dossier_id/description en #POST' do
      expect(rendered).to have_selector("form[action='/users/dossiers/#{dossier_id}/description'][method=post]")
    end

    it 'Charger votre CERFA (PDF)' do
      expect(rendered).to have_selector('input[type=file][name=cerfa_pdf][id=cerfa_pdf]')
    end

    it 'Lien CERFA' do
      expect(rendered).to have_selector('#lien_cerfa')
    end
  end

  context 'si la page précédente n\'est pas recapitulatif' do
    before do
      render
    end
    it 'le bouton "Terminer" est présent' do
      expect(rendered).to have_selector('#suivant')
    end
  end

  context 'si la page précédente est recapitularif' do
    before do
      dossier.en_construction!
      dossier.reload
      render
    end

    it 'le bouton "Terminer" n\'est pas présent' do
      expect(rendered).to_not have_selector('#suivant')
    end

    it 'le bouton "Modification terminé" est présent' do
      expect(rendered).to have_selector('#modification_terminee')
    end

    it 'le lien de retour au récapitulatif est présent' do
      expect(rendered).to have_selector("a[href='/users/dossiers/#{dossier_id}/recapitulatif']")
    end
  end

  context 'Champs' do
    let(:champs) { dossier.champs }
    let(:types_de_champ) { procedure.types_de_champ.where(type_champ: 'datetime').first }
    let(:champ_datetime) { champs.where(type_de_champ_id: types_de_champ.id).first }

    before do
      champ_datetime.value = "22/06/2016 12:05"
      champ_datetime.save
      render
    end

    describe 'first champs' do
      subject { dossier.champs.first }
      it { expect(rendered).to have_css("#champs_#{subject.id}") }
    end

    describe 'last champs' do
      subject { dossier.champs.last }
      it { expect(rendered).to have_css("#champs_#{subject.id}") }
    end

    describe 'datetime value is correctly setup when is not nil' do
      it { expect(rendered).to have_css("input[type='datetime'][id='champs_#{champ_datetime.id}'][value='22/06/2016']") }
      it { expect(rendered).to have_css("option[value='12'][selected='selected']")}
      it { expect(rendered).to have_css("option[value='05'][selected='selected']")}
    end
  end

  context 'Pièces justificatives' do
    let(:all_type_pj_procedure_id) { dossier.procedure.type_de_piece_justificative_ids }

    before do
      render
    end

    context 'la liste des pièces justificatives a envoyé est affichée' do
      it 'RIB' do
        expect(rendered).to have_css("#piece_justificative_#{all_type_pj_procedure_id[0]}")
      end
    end
  end

  context 'Envoi des CERFA désactivé' do
    let!(:cerfa_flag) { false }

    before do
      render
    end

    it { expect(rendered).to_not have_css("#cerfa_flag") }
    it { expect(rendered).to_not have_selector('input[type=file][name=cerfa_pdf][id=cerfa_pdf]') }
  end

  describe 'display title Documents administratifs' do
    before do
      render
    end

    let(:procedure) { create :procedure, lien_demarche: '' }
    let(:dossier) { create(:dossier, procedure: procedure) }

    context 'when dossier not have cerfa, piece justificative and demarche link' do
      it { expect(rendered).not_to have_content 'Documents administratifs' }
    end
  end
end
