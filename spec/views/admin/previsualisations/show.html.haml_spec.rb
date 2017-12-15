require 'spec_helper'

describe 'admin/previsualisations/show.html.haml', type: :view do
  before do
    @request.env['HTTP_REFERER'] = admin_procedures_url
  end

  let(:user) { create(:user) }
  let(:cerfa_flag) { true }
  let(:procedure) { create(:procedure, :with_two_type_de_piece_justificative, :with_type_de_champ, cerfa_flag: cerfa_flag) }
  let(:dossier) { create(:dossier, procedure: procedure, user: user) }
  let(:dossier_id) { dossier.id }

  before do
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
    it 'le bouton "Terminer" n\'est pas présent' do
      expect(rendered).not_to have_selector('#suivant')
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

    it 'le bouton "Modification terminé" n\'est pas présent' do
      expect(rendered).not_to have_selector('#modification_terminee')
    end

    it 'le lien de retour au récapitulatif n\'est pas présent' do
      expect(rendered).not_to have_selector("a[href='/users/dossiers/#{dossier_id}/recapitulatif']")
    end
  end

  context 'les valeurs sont réaffichées si elles sont présentes dans la BDD' do
    let!(:dossier) do
      create(:dossier, user: user)
    end

    before do
      render
    end
  end

  context 'Champs' do
    let(:champs) { dossier.champs }

    before do
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
