# frozen_string_literal: true

require "rails_helper"

module Maintenance
  RSpec.describe T20251030warnOfPossibleAlterationTask do
    describe "#process" do
      subject(:process) { described_class.process(row) }

      context "when dossier does not exist" do
        let(:row) { { "dossier_id" => "999999" } }

        it "does not raise an error" do
          expect { process }.not_to raise_error
        end

        it "does not create a commentaire" do
          expect { process }.not_to change { Commentaire.count }
        end
      end

      context "when dossier exists" do
        let(:procedure) { create(:procedure, :published) }
        let(:dossier) { create(:dossier, :en_instruction, procedure: procedure) }
        let(:instructeur) { create(:instructeur) }
        let(:row) { { "dossier_id" => dossier.id.to_s } }

        before do
          instructeur.groupe_instructeurs << dossier.groupe_instructeur
          dossier.followers_instructeurs << instructeur
        end

        it "creates a commentaire with warning message and a notification" do
          expect { process }
            .to change { Commentaire.count }.by(1)
            .and change { DossierNotification.count }.by(1)

          commentaire = Commentaire.last
          expect(commentaire.dossier).to eq(dossier)
          expect(commentaire.email).to eq(CONTACT_EMAIL)
          expect(commentaire.body).to include("Une anomalie technique a affecté ce dossier")

          notification = DossierNotification.last
          expect(notification.dossier).to eq(dossier)
          expect(notification.notification_type).to eq("message")
        end
      end
    end
  end
end
