require 'spec_helper'

describe SIADE::EtablissementAdapter do

  context 'SIRET valide' do
    let(:siret){41816609600051}
    subject { SIADE::EtablissementAdapter.new(siret).to_params }

    before do
      stub_request(:get, "https://api-dev.apientreprise.fr/api/v1/etablissements/#{siret}?token=#{SIADETOKEN}")
      .to_return(body: File.read('spec/support/files/etablissement.json', status: 200))
    end

    it '#to_params class est une Hash ?' do
      expect(subject.class).to eq (Hash)
    end

    context 'Attributs Etablissements' do

      it 'L\'entreprise contient bien un siret' do
        expect(subject[:siret]).to eq('41816609600051')
      end

      it 'L\'entreprise contient bien un siege_social' do
        expect(subject[:siege_social]).to eq(true)
      end

      it 'L\'entreprise contient bien un naf' do
        expect(subject[:naf]).to eq('6202A')
      end

      it 'L\'entreprise contient bien un libelle_naf' do
        expect(subject[:libelle_naf]).to eq('Conseil en systèmes et logiciels informatiques')
      end

      context 'Concaténation lignes adresse' do
        it 'L\'entreprise contient bien une adresse sur plusieurs lignes' do
          expect(subject[:adresse]).to eq("OCTO-TECHNOLOGY\r\n50 AV DES CHAMPS ELYSEES\r\n75008 PARIS 8\r\nligne 4\r\nligne 5\r\n")
        end
      end

      context 'Détails adresse' do
        it 'L\'entreprise contient bien un numero_voie' do
          expect(subject[:numero_voie]).to eq('50')
        end

        it 'L\'entreprise contient bien un type_voie' do
          expect(subject[:type_voie]).to eq('AV')
        end

        it 'L\'entreprise contient bien un nom_voie' do
          expect(subject[:nom_voie]).to eq('DES CHAMPS ELYSEES')
        end
        it 'L\'entreprise contient bien un complement_adresse' do
          expect(subject[:complement_adresse]).to eq('complement_adresse')
        end

        it 'L\'entreprise contient bien un code_postal' do
          expect(subject[:code_postal]).to eq('75008')
        end

        it 'L\'entreprise contient bien une localite' do
          expect(subject[:localite]).to eq('PARIS 8')
        end

        it 'L\'entreprise contient bien un code_insee_localite' do
          expect(subject[:code_insee_localite]).to eq('75108')
        end
      end
    end
  end

  context 'SIRET Inconnu' do
    let(:bad_siret){1}
    subject { SIADE::EtablissementAdapter.new(bad_siret).to_params }

    before do
      stub_request(:get, "https://api-dev.apientreprise.fr/api/v1/etablissements/#{bad_siret}?token=#{SIADETOKEN}")
      .to_return(body: 'Fake body', status: 404)
    end

    it 'retour de nil' do
      expect{subject}.to raise_error ('SIRET Non reconnu')
    end
  end
end