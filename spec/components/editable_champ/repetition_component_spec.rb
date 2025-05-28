# frozen_string_literal: true

describe EditableChamp::RepetitionComponent, type: :component do
  describe "aria-labelledby" do
    subject(:render) do
      component = nil
      ActionView::Base.empty.form_for(repetition_champ, url: '/') do |form|
        component = described_class.new(champ: repetition_champ, form:)
      end

      render_inline(component)
    end

    context "when the procedure has only one champ per row" do
      let(:procedure) { create(:procedure, types_de_champ_public: [{ type: :repetition, libelle: 'Enfants', children: [{ type: :text, libelle: 'Prénom' }] }]) }
      let(:dossier) { create(:dossier, :with_populated_champs, procedure:) }
      let(:repetition_champ) { dossier.project_champs_public.first }
      let(:text_champ) { repetition_champ.rows.first.first }

      it "should have an aria-labelledby that contains the id of the champ fieldset and the label id" do
        # we should match
        # aria-labelledby="champ-66-legend champ-67-01JWAZPQ0MZFCTPJ4SRV8YSGP2-label"
        expect(subject).to have_selector("input[aria-labelledby='#{repetition_champ.html_id}-legend #{text_champ.html_id}-label']")
      end
    end

    context "when the procedure has multiple champs per row" do
      let(:procedure) { create(:procedure, types_de_champ_public: [{ type: :repetition, libelle: 'Enfants', children: [{ type: :text, libelle: 'Prénom' }, { type: :text, libelle: 'Nom' }] }]) }
      let(:dossier) { create(:dossier, :with_populated_champs, procedure:) }
      let(:repetition_champ) { dossier.project_champs_public.first }
      let(:text_champ) { repetition_champ.rows.first.first }
      let(:text_champ_2) { repetition_champ.rows.first.last }

      it "should have an aria-labelledby that contains the id of the row fieldset and the label id" do
        # we should match
        # aria-labelledby='champ-110-01JWB4MXPDCFFKMBBGA01FY0M6-legend champ-111-01JWB4MXPDCFFKMBBGA01FY0M6-label'
        expect(subject).to have_selector("input[aria-labelledby='#{repetition_champ.type_de_champ.html_id(text_champ.row_id)}-legend #{text_champ.html_id}-label']")
        expect(subject).to have_selector("input[aria-labelledby='#{repetition_champ.type_de_champ.html_id(text_champ_2.row_id)}-legend #{text_champ_2.html_id}-label']")
      end
    end
  end
end
