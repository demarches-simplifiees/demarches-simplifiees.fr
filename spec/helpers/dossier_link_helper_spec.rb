# frozen_string_literal: true

describe DossierLinkHelper do
  describe "#dossier_linked_path" do
    context "when no access as a instructeur" do
      let(:instructeur) { create(:instructeur) }
      let(:dossier) { create(:dossier) }

      it { expect(helper.dossier_linked_path(instructeur, dossier)).to be_nil }
    end

    context "when no access as a user" do
      let(:user) { create(:user) }
      let(:dossier) { create(:dossier) }

      it { expect(helper.dossier_linked_path(user, dossier)).to be_nil }
    end

    context "when access as instructeur" do
      let(:procedure) { create(:procedure, :routee) }
      let(:dossier) { create(:dossier, groupe_instructeur: procedure.groupe_instructeurs.last) }
      let(:instructeur) { create(:instructeur) }

      before { procedure.groupe_instructeurs.last.instructeurs << instructeur }

      it { expect(helper.dossier_linked_path(instructeur, dossier)).to eq(instructeur_dossier_path(dossier.procedure, dossier)) }
    end

    context "when access as user" do
      let(:dossier) { create(:dossier) }
      let(:user) { create(:user) }

      before { dossier.user = user }

      it { expect(helper.dossier_linked_path(user, dossier)).to eq(dossier_path(dossier)) }
    end
  end
end
