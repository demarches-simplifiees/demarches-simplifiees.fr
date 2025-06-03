# frozen_string_literal: true

RSpec.describe Dossiers::NoAccessToDossierComponent, type: :component do
  let(:dossier) { create(:dossier) }
  subject { render_inline(described_class.new(dossier)) }

  context "when has administrators" do
    it "renders text properly" do
      expect(subject).to have_text("Pour consulter ce dossier, vous devez contacter l'un des administrateurs \nde la démarche \"#{dossier.procedure.libelle}\" pour lui demander de vous ajouter comme instructeur :")
      # bold (<b>) is adding new lines to the test
    end

    it "renders procedure name" do
      expect(subject).to have_text(dossier.procedure.libelle)
    end

    it "renders administrator email" do
      expect(subject).to have_link("default_admin@admin.com")
    end

    it "renders title" do
      expect(subject).to have_text("Vous n'avez pas accès à ce dossier")
    end

    it "renders dossier number link" do
      expect(subject).to have_link("Dossier nº #{dossier.id}")
    end

    it "renders close button" do
      expect(subject).to have_button("Fermer")
    end
  end
end
