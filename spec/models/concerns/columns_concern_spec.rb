# frozen_string_literal: true

describe ColumnsConcern do
  describe "#columns" do
    subject { procedure.columns }

    context 'when the procedure can have a SIRET number' do
      let(:procedure) { create(:procedure, types_de_champ_public:, types_de_champ_private:) }
      let(:tdc_1) { procedure.active_revision.types_de_champ_public[0] }
      let(:tdc_2) { procedure.active_revision.types_de_champ_public[1] }
      let(:tdc_private_1) { procedure.active_revision.types_de_champ_private[0] }
      let(:tdc_private_2) { procedure.active_revision.types_de_champ_private[1] }
      let(:expected) {
        [
          { label: 'Nº dossier', table: 'self', column: 'id', classname: 'number-col', displayable: true, type: :text, scope: '', value_column: :value, filterable: true },
          { label: 'notifications', table: 'notifications', column: 'notifications', displayable: true, type: :text, scope: '', value_column: :value, filterable: false },
          { label: 'Créé le', table: 'self', column: 'created_at', classname: '', displayable: true, type: :date, scope: '', value_column: :value, filterable: true },
          { label: 'Mis à jour le', table: 'self', column: 'updated_at', classname: '', displayable: true, type: :date, scope: '', value_column: :value, filterable: true },
          { label: 'Déposé le', table: 'self', column: 'depose_at', classname: '', displayable: true, type: :date, scope: '', value_column: :value, filterable: true },
          { label: 'En construction le', table: 'self', column: 'en_construction_at', classname: '', displayable: true, type: :date, scope: '', value_column: :value, filterable: true },
          { label: 'En instruction le', table: 'self', column: 'en_instruction_at', classname: '', displayable: true, type: :date, scope: '', value_column: :value, filterable: true },
          { label: 'Terminé le', table: 'self', column: 'processed_at', classname: '', displayable: true, type: :date, scope: '', value_column: :value, filterable: true },
          { label: "Mis à jour depuis", table: "self", column: "updated_since", classname: "", displayable: false, type: :date, scope: '', value_column: :value, filterable: true },
          { label: "Déposé depuis", table: "self", column: "depose_since", classname: "", displayable: false, type: :date, scope: '', value_column: :value, filterable: true },
          { label: "En construction depuis", table: "self", column: "en_construction_since", classname: "", displayable: false, type: :date, scope: '', value_column: :value, filterable: true },
          { label: "En instruction depuis", table: "self", column: "en_instruction_since", classname: "", displayable: false, type: :date, scope: '', value_column: :value, filterable: true },
          { label: "Terminé depuis", table: "self", column: "processed_since", classname: "", displayable: false, type: :date, scope: '', value_column: :value, filterable: true },
          { label: "Statut", table: "self", column: "state", classname: "", displayable: false, scope: 'instructeurs.dossiers.filterable_state', type: :enum, value_column: :value, filterable: true },
          { label: 'Demandeur', table: 'user', column: 'email', classname: '', displayable: true, type: :text, scope: '', value_column: :value, filterable: true },
          { label: 'Email instructeur', table: 'followers_instructeurs', column: 'email', classname: '', displayable: true, type: :text, scope: '', value_column: :value, filterable: true },
          { label: 'Groupe instructeur', table: 'groupe_instructeur', column: 'id', classname: '', displayable: true, type: :enum, scope: '', value_column: :value, filterable: true },
          { label: 'Avis oui/non', table: 'avis', column: 'question_answer', classname: '', displayable: true, type: :text, scope: '', value_column: :value, filterable: false },
          { label: 'SIREN', table: 'etablissement', column: 'entreprise_siren', classname: '', displayable: true, type: :text, scope: '', value_column: :value, filterable: true },
          { label: 'Forme juridique', table: 'etablissement', column: 'entreprise_forme_juridique', classname: '', displayable: true, type: :text, scope: '', value_column: :value, filterable: true },
          { label: 'Nom commercial', table: 'etablissement', column: 'entreprise_nom_commercial', classname: '', displayable: true, type: :text, scope: '', value_column: :value, filterable: true },
          { label: 'Raison sociale', table: 'etablissement', column: 'entreprise_raison_sociale', classname: '', displayable: true, type: :text, scope: '', value_column: :value, filterable: true },
          { label: 'Numéro TAHITI siège social', table: 'etablissement', column: 'entreprise_siret_siege_social', classname: '', displayable: true, type: :text, scope: '', value_column: :value, filterable: true },
          { label: 'Date de création', table: 'etablissement', column: 'entreprise_date_creation', classname: '', displayable: true, type: :date, scope: '', value_column: :value, filterable: true },
          { label: 'Numéro TAHITI', table: 'etablissement', column: 'siret', classname: '', displayable: true, type: :text, scope: '', value_column: :value, filterable: true },
          { label: 'Libellé NAF', table: 'etablissement', column: 'libelle_naf', classname: '', displayable: true, type: :text, scope: '', value_column: :value, filterable: true },
          { label: 'Code postal', table: 'etablissement', column: 'code_postal', classname: '', displayable: true, type: :text, scope: '', value_column: :value, filterable: true },
          { label: tdc_1.libelle, table: 'type_de_champ', column: tdc_1.stable_id.to_s, classname: '', displayable: true, type: :text, scope: '', value_column: :value, filterable: true },
          { label: tdc_2.libelle, table: 'type_de_champ', column: tdc_2.stable_id.to_s, classname: '', displayable: true, type: :text, scope: '', value_column: :value, filterable: true },
          { label: tdc_private_1.libelle, table: 'type_de_champ', column: tdc_private_1.stable_id.to_s, classname: '', displayable: true, type: :text, scope: '', value_column: :value, filterable: true },
          { label: tdc_private_2.libelle, table: 'type_de_champ', column: tdc_private_2.stable_id.to_s, classname: '', displayable: true, type: :text, scope: '', value_column: :value, filterable: true }
        ].map { Column.new(**_1) }
      }

      context 'with explication/header_sections' do
        let(:types_de_champ_public) { Array.new(4) { { type: :text } } }
        let(:types_de_champ_private) { Array.new(4) { { type: :text } } }
        before do
          procedure.active_revision.types_de_champ_public[2].update_attribute(:type_champ, TypeDeChamp.type_champs.fetch(:header_section))
          procedure.active_revision.types_de_champ_public[3].update_attribute(:type_champ, TypeDeChamp.type_champs.fetch(:explication))
          procedure.active_revision.types_de_champ_private[2].update_attribute(:type_champ, TypeDeChamp.type_champs.fetch(:header_section))
          procedure.active_revision.types_de_champ_private[3].update_attribute(:type_champ, TypeDeChamp.type_champs.fetch(:explication))
        end

        it { expect(subject).to eq(expected) }
      end

      context 'with rna' do
        let(:types_de_champ_public) { [{ type: :rna, libelle: 'rna' }] }
        let(:types_de_champ_private) { [] }
        it { expect(subject.map(&:label)).to include('rna – commune') }
      end
    end

    context 'when the procedure is for individuals' do
      let(:name_field) { Column.new(label: "Prénom", table: "individual", column: "prenom", classname: '', displayable: true, type: :text, scope: '', value_column: :value, filterable: true) }
      let(:surname_field) { Column.new(label: "Nom", table: "individual", column: "nom", classname: '', displayable: true, type: :text, scope: '', value_column: :value, filterable: true) }
      let(:gender_field) { Column.new(label: "Civilité", table: "individual", column: "gender", classname: '', displayable: true, type: :text, scope: '', value_column: :value, filterable: true) }
      let(:procedure) { create(:procedure, :for_individual) }
      let(:procedure_presentation) { create(:procedure_presentation, assign_to: assign_to) }

      it { is_expected.to include(name_field, surname_field, gender_field) }
    end

    context 'when the procedure is sva' do
      let(:procedure) { create(:procedure, :for_individual, :sva) }
      let(:procedure_presentation) { create(:procedure_presentation, assign_to: assign_to) }

      let(:decision_on) { Column.new(label: "Date décision SVA", table: "self", column: "sva_svr_decision_on", classname: '', displayable: true, type: :date, scope: '', value_column: :value, filterable: true) }
      let(:decision_before_field) { Column.new(label: "Date décision SVA avant", table: "self", column: "sva_svr_decision_before", classname: '', displayable: false, type: :date, scope: '', value_column: :value, filterable: true) }

      it { is_expected.to include(decision_on, decision_before_field) }
    end

    context 'when the procedure is svr' do
      let(:procedure) { create(:procedure, :for_individual, :svr) }
      let(:procedure_presentation) { create(:procedure_presentation, assign_to: assign_to) }

      let(:decision_on) { Column.new(label: "Date décision SVR", table: "self", column: "sva_svr_decision_on", classname: '', displayable: true, type: :date, scope: '', value_column: :value, filterable: true) }
      let(:decision_before_field) { Column.new(label: "Date décision SVR avant", table: "self", column: "sva_svr_decision_before", classname: '', displayable: false, type: :date, scope: '', value_column: :value, filterable: true) }

      it { is_expected.to include(decision_on, decision_before_field) }
    end
  end
end
