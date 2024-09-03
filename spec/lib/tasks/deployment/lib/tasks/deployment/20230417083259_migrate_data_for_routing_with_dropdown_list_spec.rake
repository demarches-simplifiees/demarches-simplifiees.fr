# frozen_string_literal: true

describe '20230417083259_migrate_data_for_routing_with_dropdown_list' do
  include Logic
  let(:rake_task) { Rake::Task['after_party:migrate_data_for_routing_with_dropdown_list'] }
  subject(:run_task) { rake_task.invoke }
  after(:each) { rake_task.reenable }

  describe 'migrates data for routing with drop down lists' do
    context 'with a non routed procedure' do
      let(:procedure) { create(:procedure, types_de_champ_public: [{ type: :yes_no }]) }
      it 'works' do
        expect(procedure.draft_types_de_champ_public.pluck(:type_champ)).to match(['yes_no'])

        run_task

        procedure.reload

        expect(procedure.draft_types_de_champ_public.pluck(:type_champ)).to match(['yes_no'])
        expect(procedure.migrated_champ_routage).to be nil
      end
    end

    context 'with a routed procedure' do
      let(:procedure) do
        create(:procedure, routing_criteria_name: 'Ma région', types_de_champ_public: [{ type: :yes_no }, { type: :repetition, children: [{ type: :text }] }]).tap do |p|
          p.groupe_instructeurs.create(label: "a second group")
        end
      end
      let(:dossier_without_gi) { create(:dossier, procedure:) }
      let(:dossier_with_gi) { create(:dossier, procedure:, groupe_instructeur: defaut_groupe_instructeur) }
      let(:drop_down_list) { procedure.reload.draft_types_de_champ_public.first }
      let(:defaut_groupe_instructeur) { procedure.defaut_groupe_instructeur }

      it 'works' do
        expect(procedure.draft_revision.types_de_champ.pluck(:type_champ, :position)).to match([["yes_no", 0], ["text", 0], ["repetition", 1]])
        expect(dossier_without_gi.champs.pluck(:type)).to match(["Champs::YesNoChamp", "Champs::RepetitionChamp"])
        expect(dossier_with_gi.champs.pluck(:type)).to match(["Champs::YesNoChamp", "Champs::RepetitionChamp"])

        run_task

        [procedure, defaut_groupe_instructeur, dossier_without_gi, dossier_with_gi].each(&:reload)

        expect(procedure.draft_revision.types_de_champ.pluck(:type_champ, :position)).to match([["text", 0], ["drop_down_list", 0], ["yes_no", 1], ["repetition", 2]])
        expect(drop_down_list.libelle).to eq('Ma région')
        expect(drop_down_list.options).to eq({ "drop_down_options" => ["", "a second group", "défaut"] })
        expect(defaut_groupe_instructeur.routing_rule).to eq(ds_eq(champ_value(drop_down_list.stable_id), constant(defaut_groupe_instructeur.label)))
        expect(procedure.migrated_champ_routage).to be_truthy
        expect(dossier_without_gi.champs.pluck(:type)).to match_array(["Champs::DropDownListChamp", "Champs::YesNoChamp", "Champs::RepetitionChamp"])
        expect(drop_down(dossier_without_gi).value).to eq nil
        expect(dossier_with_gi.champs.pluck(:type)).to match_array(["Champs::DropDownListChamp", "Champs::YesNoChamp", "Champs::RepetitionChamp"])
        expect(drop_down(dossier_with_gi).value).to eq procedure.defaut_groupe_instructeur.label
      end
    end

    def drop_down(dossier)
      dossier.champs.find_by(type: 'Champs::DropDownListChamp')
    end
  end
end
