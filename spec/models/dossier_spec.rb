require 'spec_helper'

describe Dossier do
  describe 'database columns' do
    it { is_expected.to have_db_column(:description) }
    it { is_expected.to have_db_column(:autorisation_donnees) }
    it { is_expected.to have_db_column(:position_lat) }
    it { is_expected.to have_db_column(:position_lon) }
    it { is_expected.to have_db_column(:ref_dossier) }
    it { is_expected.to have_db_column(:nom_projet) }
    it { is_expected.to have_db_column(:montant_projet) }
    it { is_expected.to have_db_column(:montant_aide_demande) }
    it { is_expected.to have_db_column(:date_previsionnelle).of_type(:date) }
    it { is_expected.to have_db_column(:lien_plus_infos) }
    it { is_expected.to have_db_column(:mail_contact) }
    it { is_expected.to have_db_column(:dossier_termine) }
  end

  describe 'associations' do
    it { is_expected.to belong_to(:formulaire) }
    it { is_expected.to have_many(:pieces_jointes) }
    it { is_expected.to have_many(:commentaires) }
    it { is_expected.to have_one(:cerfa) }
    it { is_expected.to have_one(:etablissement) }
    it { is_expected.to have_one(:entreprise) }
  end

  describe 'delegation' do
    it { is_expected.to delegate_method(:siren).to(:entreprise) }
    it { is_expected.to delegate_method(:siret).to(:etablissement) }
    it { is_expected.to delegate_method(:types_piece_jointe).to(:formulaire) }
  end

  describe 'validation' do
    context 'mail_contact' do
      it { is_expected.to allow_value('tanguy@plop.com').for(:mail_contact) }
      it { is_expected.not_to allow_value('tanguyplop.com').for(:mail_contact) }
    end
    context 'nom_projet' do
      it { is_expected.to allow_value(nil).for(:nom_projet) }
      it { is_expected.not_to allow_value('').for(:nom_projet) }
      it { is_expected.to allow_value('mon super projet').for(:nom_projet) }
    end
    context 'description' do
      it { is_expected.to allow_value(nil).for(:description) }
      it { is_expected.not_to allow_value('').for(:description) }
      it { is_expected.to allow_value('ma superbe description').for(:description) }
    end
    context 'montant_projet' do
      it { is_expected.to allow_value(nil).for(:montant_projet) }
      it { is_expected.not_to allow_value('').for(:montant_projet) }
      it { is_expected.to allow_value(124324).for(:montant_projet) }
    end
    context 'montant_aide_demande' do
      it { is_expected.to allow_value(nil).for(:montant_aide_demande) }
      it { is_expected.not_to allow_value('').for(:montant_aide_demande) }
      it { is_expected.to allow_value(124324).for(:montant_aide_demande) }
    end
  end

  describe 'methods' do
    let(:dossier) { create(:dossier, :with_entreprise) }

    let(:entreprise) { dossier.entreprise }
    let(:etablissement) { dossier.etablissement }

    subject { dossier }

    describe '#types_piece_jointe' do
      subject { dossier.types_piece_jointe }
      it 'returns list of required piece justificative' do
        expect(subject.size).to eq(7)
        expect(subject).to include(TypePieceJointe.find(103))
      end
    end

    describe 'creation' do
      it 'create default cerfa' do
        expect { described_class.create }.to change { Cerfa.count }.by(1)
      end

      it 'link cerfa to dossier' do
        dossier = described_class.create
        expect(dossier.cerfa).to eq(Cerfa.last)
      end
    end

    describe '#retrieve_piece_jointe_by_type' do
      let(:type) { 93 }
      subject { dossier.retrieve_piece_jointe_by_type type }
      before do
        dossier.build_default_pieces_jointes
      end

      it 'returns piece jointe with given type' do
        expect(subject.type).to eq(93)
      end
    end

    describe '#build_default_pieces_jointes' do
      context 'when dossier is linked to a formulaire' do
        let(:dossier) { create(:dossier) }
        it 'build all pieces jointes needed' do
          expect(dossier.pieces_jointes.count).to eq(7)
        end
      end
    end

    describe '#save' do
      subject { create(:dossier, formulaire_id: nil) }
      context 'when is linked to a formulaire' do
        it 'creates default pieces jointes' do
          expect(subject).to receive(:build_default_pieces_jointes)
          subject.update_attributes(formulaire_id: 1)
        end
      end
      context 'when is not linked to a formulaire' do
        it 'does not create default pieces jointes' do
          expect(subject).not_to receive(:build_default_pieces_jointes)
          subject.update_attributes(description: 'plop')
        end
      end
    end

    describe '#mailto' do
      let(:dossier) { create(:dossier) }
      let(:email_contact) { dossier.formulaire.email_contact }
      subject { dossier.mailto }
      it { is_expected.to eq("mailto:#{email_contact}?subject=Demande%20de%20contact&body=Bonjour,%0A%0AJe%20vous%20informe%20que%20j'ai%20rempli%20le%20dossier%20sur%20admi_facile.%20Vous%20pouvez%20y%20acc%C3%A9der%20en%20suivant%20le%20lien%20suivant%20:%20%0Ahttps://admi_facile.apientreprise.fr/admin/dossiers/#{dossier.id}%20%0A%20Le%20num%C3%A9ro%20de%20mon%20dossier%20est%20le%20#{dossier.id}")}
    end
  end
end
