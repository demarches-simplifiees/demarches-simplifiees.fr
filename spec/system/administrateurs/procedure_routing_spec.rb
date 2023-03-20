describe 'As an administrateur I can manage procedure routing', js: true do
  include Logic

  let(:administrateur) { procedure.administrateurs.first }
  let!(:gi_1) { procedure.defaut_groupe_instructeur }
  let!(:gi_2) { procedure.groupe_instructeurs.create(label: 'a second group') }
  let!(:gi_3) { procedure.groupe_instructeurs.create(label: 'a third group') }

  let(:procedure) do
    create(:procedure).tap do |p|
      p.draft_revision.add_type_de_champ(
        type_champ: :drop_down_list,
        libelle: 'Un champ choix simple',
        options: { "drop_down_other" => "0", "drop_down_options" => ["", "Premier choix", "Deuxième choix", "Troisième choix"] }
      )
    end
  end

  let(:drop_down_tdc) { procedure.draft_revision.types_de_champ.first }

  before do
    Flipper.enable(:routing_rules, procedure)
    procedure.publish_revision!
    login_as administrateur.user, scope: :user
  end

  it 'routes from a drop_down_list' do
    visit admin_procedure_groupe_instructeurs_path(procedure)

    within('.condition-table tbody tr:nth-child(1)', match: :first) do
      expect(page).to have_select('targeted_champ', options: ['Sélectionner', 'Un champ choix simple'])
      within('.target') { select('Un champ choix simple') }
      within('.value') { select('Premier choix') }
    end

    expected_routing_rule = ds_eq(champ_value(drop_down_tdc.stable_id), constant('Premier choix'))
    wait_until { gi_2.reload.routing_rule == expected_routing_rule }
  end

  it 'displays groupes instructeurs by alphabetic order' do
    visit admin_procedure_groupe_instructeurs_path(procedure)

    within('.condition-table tbody tr:nth-child(1)', match: :first) do
      expect(page).to have_content 'Router vers « a second group »'
      expect(page).not_to have_content 'Router vers « défaut »'
    end
  end
end
