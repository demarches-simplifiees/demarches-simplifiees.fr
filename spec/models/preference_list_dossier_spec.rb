require 'spec_helper'

describe PreferenceListDossier do
  it { is_expected.to have_db_column(:libelle) }
  it { is_expected.to have_db_column(:table) }
  it { is_expected.to have_db_column(:attr) }
  it { is_expected.to have_db_column(:attr_decorate) }
  it { is_expected.to have_db_column(:bootstrap_lg) }
  it { is_expected.to have_db_column(:order) }
  it { is_expected.to have_db_column(:filter) }
  it { is_expected.to have_db_column(:gestionnaire_id) }

  it { is_expected.to belong_to(:gestionnaire) }
  it { is_expected.to belong_to(:procedure) }

  describe '.available_columns' do
    subject { PreferenceListDossier.available_columns }

    describe 'dossier' do
      subject { super()[:dossier] }

      it { expect(subject.size).to eq 4 }

      describe 'dossier_id' do
        subject { super()[:dossier_id] }

        it { expect(subject[:libelle]).to eq 'ID' }
        it { expect(subject[:table]).to be_nil }
        it { expect(subject[:attr]).to eq 'id' }
        it { expect(subject[:attr_decorate]).to eq 'id' }
        it { expect(subject[:bootstrap_lg]).to eq 1 }
        it { expect(subject[:order]).to be_nil }
        it { expect(subject[:filter]).to be_nil }
      end

      describe 'created_at' do
        subject { super()[:created_at] }

        it { expect(subject[:libelle]).to eq 'Créé le' }
        it { expect(subject[:table]).to be_nil }
        it { expect(subject[:attr]).to eq 'created_at' }
        it { expect(subject[:attr_decorate]).to eq 'first_creation' }
        it { expect(subject[:bootstrap_lg]).to eq 2 }
        it { expect(subject[:order]).to be_nil }
        it { expect(subject[:filter]).to be_nil }
      end

      describe 'updated_at' do
        subject { super()[:updated_at] }

        it { expect(subject[:libelle]).to eq 'Mise à jour le' }
        it { expect(subject[:table]).to be_nil }
        it { expect(subject[:attr]).to eq 'updated_at' }
        it { expect(subject[:attr_decorate]).to eq 'last_update' }
        it { expect(subject[:bootstrap_lg]).to eq 2 }
        it { expect(subject[:order]).to be_nil }
        it { expect(subject[:filter]).to be_nil }
      end

      describe 'state' do
        subject { super()[:state] }

        it { expect(subject[:libelle]).to eq 'Statut' }
        it { expect(subject[:table]).to be_nil }
        it { expect(subject[:attr]).to eq 'state' }
        it { expect(subject[:attr_decorate]).to eq 'display_state' }
        it { expect(subject[:bootstrap_lg]).to eq 1 }
        it { expect(subject[:order]).to be_nil }
        it { expect(subject[:filter]).to be_nil }
      end
    end

    describe 'procedure' do
      subject { super()[:procedure] }

      it { expect(subject.size).to eq 3 }

      describe 'libelle' do
        subject { super()[:libelle] }

        it { expect(subject[:libelle]).to eq 'Libellé procédure' }
        it { expect(subject[:table]).to eq 'procedure' }
        it { expect(subject[:attr]).to eq 'libelle' }
        it { expect(subject[:attr_decorate]).to eq 'libelle' }
        it { expect(subject[:bootstrap_lg]).to eq 4 }
        it { expect(subject[:order]).to be_nil }
        it { expect(subject[:filter]).to be_nil }
      end

      describe 'organisation' do
        subject { super()[:organisation] }

        it { expect(subject[:libelle]).to eq 'Organisation' }
        it { expect(subject[:table]).to eq 'procedure' }
        it { expect(subject[:attr]).to eq 'organisation' }
        it { expect(subject[:attr_decorate]).to eq 'organisation' }
        it { expect(subject[:bootstrap_lg]).to eq 3 }
        it { expect(subject[:order]).to be_nil }
        it { expect(subject[:filter]).to be_nil }
      end

      describe 'direction' do
        subject { super()[:direction] }

        it { expect(subject[:libelle]).to eq 'Direction' }
        it { expect(subject[:table]).to eq 'procedure' }
        it { expect(subject[:attr]).to eq 'direction' }
        it { expect(subject[:attr_decorate]).to eq 'direction' }
        it { expect(subject[:bootstrap_lg]).to eq 3 }
        it { expect(subject[:order]).to be_nil }
        it { expect(subject[:filter]).to be_nil }
      end
    end

    describe 'entreprise' do
      subject { super()[:entreprise] }

      it { expect(subject.size).to eq 6 }

      describe 'siren' do
        subject { super()[:siren] }

        it { expect(subject[:libelle]).to eq 'SIREN' }
        it { expect(subject[:table]).to eq 'entreprise' }
        it { expect(subject[:attr]).to eq 'siren' }
        it { expect(subject[:attr_decorate]).to eq 'siren' }
        it { expect(subject[:bootstrap_lg]).to eq 2 }
        it { expect(subject[:order]).to be_nil }
        it { expect(subject[:filter]).to be_nil }
      end

      describe 'forme_juridique' do
        subject { super()[:forme_juridique] }

        it { expect(subject[:libelle]).to eq 'Forme juridique' }
        it { expect(subject[:table]).to eq 'entreprise' }
        it { expect(subject[:attr]).to eq 'forme_juridique' }
        it { expect(subject[:attr_decorate]).to eq 'forme_juridique' }
        it { expect(subject[:bootstrap_lg]).to eq 3 }
        it { expect(subject[:order]).to be_nil }
        it { expect(subject[:filter]).to be_nil }
      end

      describe 'nom_commercial' do
        subject { super()[:nom_commercial] }

        it { expect(subject[:libelle]).to eq 'Nom commercial' }
        it { expect(subject[:table]).to eq 'entreprise' }
        it { expect(subject[:attr]).to eq 'nom_commercial' }
        it { expect(subject[:attr_decorate]).to eq 'nom_commercial' }
        it { expect(subject[:bootstrap_lg]).to eq 3 }
        it { expect(subject[:order]).to be_nil }
        it { expect(subject[:filter]).to be_nil }
      end

      describe 'raison_sociale' do
        subject { super()[:raison_sociale] }

        it { expect(subject[:libelle]).to eq 'Raison sociale' }
        it { expect(subject[:table]).to eq 'entreprise' }
        it { expect(subject[:attr]).to eq 'raison_sociale' }
        it { expect(subject[:attr_decorate]).to eq 'raison_sociale' }
        it { expect(subject[:bootstrap_lg]).to eq 3 }
        it { expect(subject[:order]).to be_nil }
        it { expect(subject[:filter]).to be_nil }
      end

      describe 'siret_siege_social' do
        subject { super()[:siret_siege_social] }

        it { expect(subject[:libelle]).to eq 'SIRET siège social' }
        it { expect(subject[:table]).to eq 'entreprise' }
        it { expect(subject[:attr]).to eq 'siret_siege_social' }
        it { expect(subject[:attr_decorate]).to eq 'siret_siege_social' }
        it { expect(subject[:bootstrap_lg]).to eq 2 }
        it { expect(subject[:order]).to be_nil }
        it { expect(subject[:filter]).to be_nil }
      end

      describe 'date_creation' do
        subject { super()[:date_creation] }

        it { expect(subject[:libelle]).to eq 'Date de création' }
        it { expect(subject[:table]).to eq 'entreprise' }
        it { expect(subject[:attr]).to eq 'date_creation' }
        it { expect(subject[:attr_decorate]).to eq 'date_creation' }
        it { expect(subject[:bootstrap_lg]).to eq 2 }
        it { expect(subject[:order]).to be_nil }
        it { expect(subject[:filter]).to be_nil }
      end

    end

    describe 'etablissement' do
      subject { super()[:etablissement] }

      it { expect(subject.size).to eq 3 }

      describe 'siret' do
        subject { super()[:siret] }

        it { expect(subject[:libelle]).to eq 'SIRET' }
        it { expect(subject[:table]).to eq 'etablissement' }
        it { expect(subject[:attr]).to eq 'siret' }
        it { expect(subject[:attr_decorate]).to eq 'siret' }
        it { expect(subject[:bootstrap_lg]).to eq 2 }
        it { expect(subject[:order]).to be_nil }
        it { expect(subject[:filter]).to be_nil }
      end

      describe 'libelle' do
        subject { super()[:libelle] }

        it { expect(subject[:libelle]).to eq 'Nom établissement' }
        it { expect(subject[:table]).to eq 'etablissement' }
        it { expect(subject[:attr]).to eq 'libelle_naf' }
        it { expect(subject[:attr_decorate]).to eq 'libelle_naf' }
        it { expect(subject[:bootstrap_lg]).to eq 3 }
        it { expect(subject[:order]).to be_nil }
        it { expect(subject[:filter]).to be_nil }
      end

      describe 'code_postal' do
        subject { super()[:code_postal] }

        it { expect(subject[:libelle]).to eq 'Code postal' }
        it { expect(subject[:table]).to eq 'etablissement' }
        it { expect(subject[:attr]).to eq 'code_postal' }
        it { expect(subject[:attr_decorate]).to eq 'code_postal' }
        it { expect(subject[:bootstrap_lg]).to eq 1 }
        it { expect(subject[:order]).to be_nil }
        it { expect(subject[:filter]).to be_nil }
      end
    end

    describe 'user' do
      subject { super()[:user] }

      it { expect(subject.size).to eq 1 }

      describe 'email' do
        subject { super()[:email] }

        it { expect(subject[:libelle]).to eq 'Email' }
        it { expect(subject[:table]).to eq 'user' }
        it { expect(subject[:attr]).to eq 'email' }
        it { expect(subject[:attr_decorate]).to eq 'email' }
        it { expect(subject[:bootstrap_lg]).to eq 2 }
        it { expect(subject[:order]).to be_nil }
        it { expect(subject[:filter]).to be_nil }
      end
    end
  end
end
