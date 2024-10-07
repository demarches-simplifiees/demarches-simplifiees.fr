# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PrefillableFromServicePublicConcern, type: :model do
  let(:siret) { '20004021000060' }
  let(:service) { build(:service, siret:) }

  describe '#prefill_from_siret' do
    let(:service) { Service.new(siret:) }
    subject { service.prefill_from_siret }
    context 'when API call is successful' do
      it 'prefills service attributes' do
        VCR.use_cassette('annuaire_service_public_success_20004021000060') do
          expect(subject).to be_success

          expect(service.nom).to eq("Communauté de communes - Lacs et Gorges du Verdon")
          expect(service.email).to eq("redacted@email.fr")
          expect(service.telephone).to eq("04 94 70 00 00")
          expect(service.horaires).to eq("Lundi au Jeudi : de 8:00 à 12:00 et de 13:30 à 17:30\nVendredi : de 8:00 à 12:00")
          expect(service.adresse).to eq("242 avenue Albert-1er 83630 Aups")
        end
      end

      it 'does not overwrite existing attributes' do
        service.nom = "Existing Name"
        service.email = "existing@email.com"

        VCR.use_cassette('annuaire_service_public_success_20004021000060') do
          service.prefill_from_siret

          expect(service.nom).to eq("Existing Name")
          expect(service.email).to eq("existing@email.com")
        end
      end
    end

    context 'when API call do not find siret' do
      let(:siret) { '20004021000000' }
      it 'returns a failure result' do
        VCR.use_cassette('annuaire_service_public_failure_20004021000000') do
          expect(subject).to be_failure
        end
      end
    end
  end

  describe '#denormalize_plage_ouverture' do
    it 'correctly formats opening hours with one time range' do
      data = [
        {
          "nom_jour_debut" => "Lundi",
                "nom_jour_fin" => "Vendredi",
                "valeur_heure_debut_1" => "09:00:00",
                "valeur_heure_fin_1" => "17:00:00"
        }
      ]
      expect(service.send(:denormalize_plage_ouverture, data)).to eq("Lundi au Vendredi : de 9:00 à 17:00")
    end

    it 'correctly formats opening hours with two time ranges' do
      data = [
        {
          "nom_jour_debut" => "Lundi",
                "nom_jour_fin" => "Jeudi",
                "valeur_heure_debut_1" => "08:00:00",
                "valeur_heure_fin_1" => "12:00:00",
                "valeur_heure_debut_2" => "13:30:00",
                "valeur_heure_fin_2" => "17:30:00"
        }, {
          "nom_jour_debut" => "Vendredi",
        "nom_jour_fin" => "Vendredi",
        "valeur_heure_debut_1" => "08:00:00",
        "valeur_heure_fin_1" => "12:00:00"
        }
      ]
      expect(service.send(:denormalize_plage_ouverture, data)).to eq("Lundi au Jeudi : de 8:00 à 12:00 et de 13:30 à 17:30\nVendredi : de 8:00 à 12:00")
    end

    it 'includes comments when present' do
      data = [
        {
          "nom_jour_debut" => "Lundi",
                "nom_jour_fin" => "Vendredi",
                "valeur_heure_debut_1" => "09:00:00",
                "valeur_heure_fin_1" => "17:00:00",
                "commentaire" => "Fermé les jours fériés"
        }
      ]
      expect(service.send(:denormalize_plage_ouverture, data)).to eq("Lundi au Vendredi : de 9:00 à 17:00 (Fermé les jours fériés)")
    end
  end
end
