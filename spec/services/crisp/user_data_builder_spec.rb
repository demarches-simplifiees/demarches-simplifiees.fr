# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Crisp::UserDataBuilder do
  let(:user) { users(:default_user) }
  let(:builder) { described_class.new(user) }

  subject(:build) { builder.build_data }

  describe '#build_data' do
    context 'without instructeur' do
      it 'retourne les liens de base' do
        data = build

        expect(data["ManagerUser"]).to include("Utilisateur ##{user.id}")
        expect(data["ManagerUser"]).to include("manager/users/#{user.id}")
        expect(data["Compte"]).to include("Email non vérifié")
      end
    end

    context 'avec instructeur' do
      let(:procedure1) { create(:procedure) }
      let(:procedure2) { create(:procedure) }
      let(:instructeur) { create(:instructeur, user:) }

      before do
        procedure1.defaut_groupe_instructeur.add(instructeur)
        procedure2.defaut_groupe_instructeur.add(instructeur)
      end

      it 'retourne le lien instructeur et décrit les statuts de notifications (désactivées par défaut)' do
        data = build

        expect(data["ManagerInstructeur"]).to include("Instructeur ##{instructeur.id}")
        expect(data["ManagerInstructeur"]).to include("manager/instructeurs/#{instructeur.id}")

        expect(data).not_to have_key("NotifsActivees")
        expect(data).to have_key("NotifsDesactivees")
        expect(data["NotifsDesactivees"]).to include("**Désactivées** sur démarche n° #{procedure1.id}, #{procedure2.id}")
      end

      it 'active une démarche et laisse l’autre désactivée' do
        assign_to_p2 = instructeur.assign_to.find { it.groupe_instructeur.procedure_id == procedure2.id }
        assign_to_p2.update!(
          instant_email_dossier_notifications_enabled: true,
          instant_email_message_notifications_enabled: true,
          instant_expert_avis_email_notifications_enabled: true
        )

        data = build
        expect(data["NotifsActivees"]).to eq("**Activées** sur démarche n° #{procedure2.id}")
        expect(data["NotifsDesactivees"]).to eq("**Désactivées** sur démarche n° #{procedure1.id}")
      end
    end
  end
end
