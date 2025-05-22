require 'rails_helper'

RSpec.describe EditableChamp::LexpolComponent, type: :component do
  let(:dossier) do
    double("Dossier", id: 42)
  end

  let(:champ) do
    double(
      "Champ",
      value: nil,
      data: {},
      lexpol_dossier_url: nil,
      lexpol_status: nil,
      stable_id: 99,
      dossier: dossier
    )
  end

  before do
    allow_any_instance_of(EditableChamp::LexpolComponent).to receive(:champs_lexpol_upsert_dossier_path)
      .and_return("/fake_upsert_path")
  end

  context "quand le champ est vide (value.blank?)" do
    it "affiche 'Créer le dossier Lexpol' et pas 'Mettre à jour le dossier lexpol'" do
      allow(champ).to receive(:value).and_return(nil)
      result = render_inline(described_class.new(form: nil, champ: champ))

      expect(result.text).to include("Button Creer Dossier")
      expect(result.text).not_to include("Button Mettre A Jour")
    end
  end

  context "quand le champ a déjà un NOR (value non vide)" do
    it "affiche 'Mettre à jour le dossier lexpol'" do
      allow(champ).to receive(:value).and_return("NOR-ABC")
      result = render_inline(described_class.new(form: nil, champ: champ))

      expect(result.text).to include("Button Mettre A Jour")
      expect(result.text).not_to include("Button Creer Dossier")
    end
  end

  context "quand le statut est 'Annulé'" do
    it "affiche le bouton 'Créer un nouveau dossier Lexpol'" do
      allow(champ).to receive(:value).and_return("NOR-XYZ")
      allow(champ).to receive(:lexpol_status).and_return("Annulé")

      result = render_inline(described_class.new(form: nil, champ: champ))
      expect(result.text).to include("Button Creer Nouveau")
    end
  end

  context "quand le champ a une URL (lexpol_dossier_url)" do
    it "affiche un lien .fr-link vers ce dossier" do
      allow(champ).to receive(:value).and_return("NOR-LINK")
      allow(champ).to receive(:lexpol_dossier_url).and_return("http://exemple.com/dossier/999")

      result = render_inline(described_class.new(form: nil, champ: champ))

      link = result.css("a.fr-link").first
      expect(link).not_to be_nil
      expect(link["href"]).to eq("http://exemple.com/dossier/999")
      expect(result.text).to include("NOR-LINK")
    end
  end
end
