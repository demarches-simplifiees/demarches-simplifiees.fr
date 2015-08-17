require 'spec_helper'

describe Formulaire do
  describe 'assocations' do
    it { is_expected.to have_many(:types_piece_jointe) }
    it { is_expected.to have_many(:dossiers) }
    it { is_expected.to belong_to(:evenement_vie) }
  end

  describe 'attributes' do
    it { is_expected.to have_db_column(:demarche_id) }
    it { is_expected.to have_db_column(:nom) }
    it { is_expected.to have_db_column(:objet) }
    it { is_expected.to have_db_column(:ministere) }
    it { is_expected.to have_db_column(:cigle_ministere) }
    it { is_expected.to have_db_column(:direction) }
    it { is_expected.to have_db_column(:evenement_vie_id) }
    it { is_expected.to have_db_column(:publics) }
    it { is_expected.to have_db_column(:lien_demarche) }
    it { is_expected.to have_db_column(:lien_fiche_signaletique) }
    it { is_expected.to have_db_column(:lien_notice) }
    it { is_expected.to have_db_column(:categorie) }
    it { is_expected.to have_db_column(:mail_pj) }
    it { is_expected.to have_db_column(:use_admi_facile) }
  end
end