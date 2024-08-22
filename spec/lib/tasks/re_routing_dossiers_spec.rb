# frozen_string_literal: true

describe 're_routing_dossiers' do
  describe 'run' do
    include Logic

    let(:admin) { administrateurs(:default_admin) }
    let(:procedure) { create(:procedure, types_de_champ_public: [{ type: :departements, libelle: 'Votre département' }], administrateurs: [admin]) }
    let(:dossier1) { create(:dossier, :en_construction, :with_populated_champs, procedure: procedure) }
    let!(:dossier2) { create(:dossier, :en_construction, :with_populated_champs, procedure: procedure) }

    before do
      dossier1.champs.last.update(value: 'Aisne')

      dossier2.champs.last.update(value: 'Allier')

      tdc = procedure.active_revision.simple_routable_types_de_champ.first

      tdc_options = APIGeoService.departements.map { ["#{_1[:code]} – #{_1[:name]}", _1[:code]] }

      rule_operator = :ds_eq

      create_groups_from_territorial_tdc(tdc_options, tdc.stable_id, rule_operator, admin)

      Rake.application.invoke_task "re_routing_dossiers:run\[#{procedure.id}\]"

      dossier1.reload
      dossier2.reload
    end

    it 'runs' do
      expect(dossier1.groupe_instructeur.label).to eq('02 – Aisne')
      expect(dossier2.groupe_instructeur.label).to eq('03 – Allier')
    end

    def create_groups_from_territorial_tdc(tdc_options, stable_id, rule_operator, administrateur)
      tdc_options.each do |label, code|
        routing_rule = send(rule_operator, champ_value(stable_id), constant(code))

        procedure
          .groupe_instructeurs
          .find_or_create_by(label: label)
          .update(instructeurs: [administrateur.instructeur], routing_rule:)
      end
    end
  end
end
