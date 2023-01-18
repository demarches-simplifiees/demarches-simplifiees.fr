describe ProcedurePresentation do
  let(:procedure) { create(:procedure, :with_type_de_champ, :with_type_de_champ_private) }
  let(:instructeur) { create(:instructeur) }
  let(:assign_to) { create(:assign_to, procedure: procedure, instructeur: instructeur) }
  let(:first_type_de_champ) { assign_to.procedure.active_revision.types_de_champ_public.first }
  let(:first_type_de_champ_id) { first_type_de_champ.stable_id.to_s }
  let(:procedure_presentation) {
    create(:procedure_presentation,
      assign_to: assign_to,
      displayed_fields: [
        { "label" => "test1", "table" => "user", "column" => "email" },
        { "label" => "test2", "table" => "type_de_champ", "column" => first_type_de_champ_id }
      ],
      sort: { "table" => "user", "column" => "email", "order" => "asc" },
      filters: filters)
  }
  let(:procedure_presentation_id) { procedure_presentation.id }
  let(:filters) { { "a-suivre" => [], "suivis" => [{ "label" => "label1", "table" => "self", "column" => "created_at" }] } }

  describe "#displayed_fields" do
    it { expect(procedure_presentation.displayed_fields).to eq([{ "label" => "test1", "table" => "user", "column" => "email" }, { "label" => "test2", "table" => "type_de_champ", "column" => first_type_de_champ_id }]) }
  end

  describe "#sort" do
    it { expect(procedure_presentation.sort).to eq({ "table" => "user", "column" => "email", "order" => "asc" }) }
  end

  describe "#filters" do
    it { expect(procedure_presentation.filters).to eq({ "a-suivre" => [], "suivis" => [{ "label" => "label1", "table" => "self", "column" => "created_at" }] }) }
  end

  describe 'validation' do
    it { expect(build(:procedure_presentation)).to be_valid }

    context 'of displayed fields' do
      it { expect(build(:procedure_presentation, displayed_fields: [{ "table" => "user", "column" => "reset_password_token", "order" => "asc" }])).to be_invalid }
    end

    context 'of sort' do
      it { expect(build(:procedure_presentation, sort: { "table" => "notifications", "column" => "notifications", "order" => "asc" })).to be_valid }
      it { expect(build(:procedure_presentation, sort: { "table" => "self", "column" => "id", "order" => "asc" })).to be_valid }
      it { expect(build(:procedure_presentation, sort: { "table" => "self", "column" => "state", "order" => "asc" })).to be_valid }
      it { expect(build(:procedure_presentation, sort: { "table" => "user", "column" => "reset_password_token", "order" => "asc" })).to be_invalid }
    end

    context 'of filters' do
      it { expect(build(:procedure_presentation, filters: { "suivis" => [{ "table" => "user", "column" => "reset_password_token", "order" => "asc" }] })).to be_invalid }
      it { expect(build(:procedure_presentation, filters: { "suivis" => [{ "table" => "user", "column" => "email", "value" => "exceedingly long filter value" * 10 }] })).to be_invalid }
    end
  end

  describe "#fields" do
    context 'when the procedure can have a SIRET number' do
      let(:procedure) { create(:procedure, :with_type_de_champ, :with_type_de_champ_private, types_de_champ_count: 4, types_de_champ_private_count: 4) }
      let(:tdc_1) { procedure.active_revision.types_de_champ_public[0] }
      let(:tdc_2) { procedure.active_revision.types_de_champ_public[1] }
      let(:tdc_private_1) { procedure.active_revision.types_de_champ_private[0] }
      let(:tdc_private_2) { procedure.active_revision.types_de_champ_private[1] }
      let(:expected) {
        [
          { "label" => 'Créé le', "table" => 'self', "column" => 'created_at', 'classname' => '', 'virtual' => false, 'type' => :date, "scope" => '' },
          { "label" => 'Mis à jour le', "table" => 'self', "column" => 'updated_at', 'classname' => '', 'virtual' => false, 'type' => :date, "scope" => '' },
          { "label" => 'Déposé le', "table" => 'self', "column" => 'depose_at', 'classname' => '', 'virtual' => false, 'type' => :date, "scope" => '' },
          { "label" => 'En construction le', "table" => 'self', "column" => 'en_construction_at', 'classname' => '', 'virtual' => false, 'type' => :date, "scope" => '' },
          { "label" => 'En instruction le', "table" => 'self', "column" => 'en_instruction_at', 'classname' => '', 'virtual' => false, 'type' => :date, "scope" => '' },
          { "label" => 'Terminé le', "table" => 'self', "column" => 'processed_at', 'classname' => '', 'virtual' => false, 'type' => :date, "scope" => '' },
          { "label" => "Mis à jour depuis", "table" => "self", "column" => "updated_since", "classname" => "", 'virtual' => true, 'type' => :date, 'scope' => '' },
          { "label" => "Déposé depuis", "table" => "self", "column" => "depose_since", "classname" => "", 'virtual' => true, 'type' => :date, 'scope' => '' },
          { "label" => "En construction depuis", "table" => "self", "column" => "en_construction_since", "classname" => "", 'virtual' => true, 'type' => :date, 'scope' => '' },
          { "label" => "En instruction depuis", "table" => "self", "column" => "en_instruction_since", "classname" => "", 'virtual' => true, 'type' => :date, 'scope' => '' },
          { "label" => "Terminé depuis", "table" => "self", "column" => "processed_since", "classname" => "", 'virtual' => true, 'type' => :date, 'scope' => '' },
          { "label" => "Statut", "table" => "self", "column" => "state", "classname" => "", 'virtual' => true, 'scope' => 'instructeurs.dossiers.filterable_state', 'type' => :enum },
          { "label" => 'Demandeur', "table" => 'user', "column" => 'email', 'classname' => '', 'virtual' => false, 'type' => :text, "scope" => '' },
          { "label" => 'Email instructeur', "table" => 'followers_instructeurs', "column" => 'email', 'classname' => '', 'virtual' => false, 'type' => :text, "scope" => '' },
          { "label" => 'Groupe instructeur', "table" => 'groupe_instructeur', "column" => 'id', 'classname' => '', 'virtual' => false, 'type' => :enum, "scope" => '' },
          { "label" => 'SIREN', "table" => 'etablissement', "column" => 'entreprise_siren', 'classname' => '', 'virtual' => false, 'type' => :text, "scope" => '' },
          { "label" => 'Forme juridique', "table" => 'etablissement', "column" => 'entreprise_forme_juridique', 'classname' => '', 'virtual' => false, 'type' => :text, "scope" => '' },
          { "label" => 'Nom commercial', "table" => 'etablissement', "column" => 'entreprise_nom_commercial', 'classname' => '', 'virtual' => false, 'type' => :text, "scope" => '' },
          { "label" => 'Raison sociale', "table" => 'etablissement', "column" => 'entreprise_raison_sociale', 'classname' => '', 'virtual' => false, 'type' => :text, "scope" => '' },
          { "label" => 'SIRET siège social', "table" => 'etablissement', "column" => 'entreprise_siret_siege_social', 'classname' => '', 'virtual' => false, 'type' => :text, "scope" => '' },
          { "label" => 'Date de création', "table" => 'etablissement', "column" => 'entreprise_date_creation', 'classname' => '', 'virtual' => false, 'type' => :date, "scope" => '' },
          { "label" => 'SIRET', "table" => 'etablissement', "column" => 'siret', 'classname' => '', 'virtual' => false, 'type' => :text, "scope" => '' },
          { "label" => 'Libellé NAF', "table" => 'etablissement', "column" => 'libelle_naf', 'classname' => '', 'virtual' => false, 'type' => :text, "scope" => '' },
          { "label" => 'Code postal', "table" => 'etablissement', "column" => 'code_postal', 'classname' => '', 'virtual' => false, 'type' => :text, "scope" => '' },
          { "label" => tdc_1.libelle, "table" => 'type_de_champ', "column" => tdc_1.stable_id.to_s, 'classname' => '', 'virtual' => false, 'type' => :text, "scope" => '' },
          { "label" => tdc_2.libelle, "table" => 'type_de_champ', "column" => tdc_2.stable_id.to_s, 'classname' => '', 'virtual' => false, 'type' => :text, "scope" => '' },
          { "label" => tdc_private_1.libelle, "table" => 'type_de_champ_private', "column" => tdc_private_1.stable_id.to_s, 'classname' => '', 'virtual' => false, 'type' => :text, "scope" => '' },
          { "label" => tdc_private_2.libelle, "table" => 'type_de_champ_private', "column" => tdc_private_2.stable_id.to_s, 'classname' => '', 'virtual' => false, 'type' => :text, "scope" => '' }
        ]
      }

      before do
        procedure.active_revision.types_de_champ_public[2].update_attribute(:type_champ, TypeDeChamp.type_champs.fetch(:header_section))
        procedure.active_revision.types_de_champ_public[3].update_attribute(:type_champ, TypeDeChamp.type_champs.fetch(:explication))
        procedure.active_revision.types_de_champ_private[2].update_attribute(:type_champ, TypeDeChamp.type_champs.fetch(:header_section))
        procedure.active_revision.types_de_champ_private[3].update_attribute(:type_champ, TypeDeChamp.type_champs.fetch(:explication))
      end

      subject { create(:procedure_presentation, assign_to: assign_to) }

      it { expect(subject.fields).to eq(expected) }
    end

    context 'when the procedure is for individuals' do
      let(:name_field) { { "label" => "Prénom", "table" => "individual", "column" => "prenom", 'classname' => '', 'virtual' => false, "type" => :text, "scope" => '' } }
      let(:surname_field) { { "label" => "Nom", "table" => "individual", "column" => "nom", 'classname' => '', 'virtual' => false, "type" => :text, "scope" => '' } }
      let(:gender_field) { { "label" => "Civilité", "table" => "individual", "column" => "gender", 'classname' => '', 'virtual' => false, "type" => :text, "scope" => '' } }
      let(:procedure) { create(:procedure, :for_individual) }
      let(:procedure_presentation) { create(:procedure_presentation, assign_to: assign_to) }

      subject { procedure_presentation.fields }

      it { is_expected.to include(name_field, surname_field, gender_field) }
    end
  end

  describe "#displayable_fields_for_select" do
    subject { create(:procedure_presentation, assign_to: assign_to) }
    let(:excluded_displayable_field) { { "label" => "depose_since", "table" => "self", "column" => "depose_since", 'virtual' => true } }
    let(:included_displayable_field) { { "label" => "label1", "table" => "table1", "column" => "column1", 'virtual' => false } }

    before do
      allow(subject).to receive(:fields).and_return([
        excluded_displayable_field,
        included_displayable_field
      ])
    end

    it { expect(subject.displayable_fields_for_select).to eq([[["label1", "table1/column1"]], ["user/email"]]) }
  end
  describe "#filterable_fields_options" do
    subject { create(:procedure_presentation, assign_to: assign_to) }
    let(:included_displayable_field) do
      [
        { "label" => "label1", "table" => "table1", "column" => "column1", 'virtual' => false },
        { "label" => "depose_since", "table" => "self", "column" => "depose_since", 'virtual' => true }
      ]
    end

    before do
      allow(subject).to receive(:fields).and_return(included_displayable_field)
    end

    it { expect(subject.filterable_fields_options).to eq([["label1", "table1/column1"], ["depose_since", "self/depose_since"]]) }
  end

  describe '#sorted_ids' do
    let(:instructeur) { create(:instructeur) }
    let(:assign_to) { create(:assign_to, procedure: procedure, instructeur: instructeur) }
    let(:sort) { { 'table' => table, 'column' => column, 'order' => order } }
    let(:procedure_presentation) { create(:procedure_presentation, assign_to: assign_to, sort: sort) }

    subject { procedure_presentation.sorted_ids(procedure.dossiers, procedure.dossiers.count) }

    context 'for notifications table' do
      let(:table) { 'notifications' }
      let(:column) { 'notifications' }

      let!(:notified_dossier) { create(:dossier, :en_construction, procedure: procedure) }
      let!(:recent_dossier) { create(:dossier, :en_construction, procedure: procedure) }
      let!(:older_dossier) { create(:dossier, :en_construction, procedure: procedure) }

      before do
        notified_dossier.update!(last_champ_updated_at: Time.zone.local(2018, 9, 20))
        create(:follow, instructeur: instructeur, dossier: notified_dossier, demande_seen_at: Time.zone.local(2018, 9, 10))
        notified_dossier.touch(time: Time.zone.local(2018, 9, 20))
        recent_dossier.touch(time: Time.zone.local(2018, 9, 25))
        older_dossier.touch(time: Time.zone.local(2018, 5, 13))
      end

      context 'in ascending order' do
        let(:order) { 'asc' }

        it { is_expected.to eq([older_dossier, recent_dossier, notified_dossier].map(&:id)) }
      end

      context 'in descending order' do
        let(:order) { 'desc' }

        it { is_expected.to eq([notified_dossier, recent_dossier, older_dossier].map(&:id)) }
      end

      context 'with a dossier terminé' do
        let!(:notified_dossier) { create(:dossier, :accepte, procedure: procedure) }
        let(:order) { 'desc' }

        it { is_expected.to eq([notified_dossier, recent_dossier, older_dossier].map(&:id)) }
      end
    end

    context 'for self table' do
      let(:table) { 'self' }
      let(:order) { 'asc' } # Desc works the same, no extra test required

      context 'for created_at column' do
        let(:column) { 'created_at' }
        let!(:recent_dossier) { Timecop.freeze(Time.zone.local(2018, 10, 17)) { create(:dossier, procedure: procedure) } }
        let!(:older_dossier) { Timecop.freeze(Time.zone.local(2003, 11, 11)) { create(:dossier, procedure: procedure) } }

        it { is_expected.to eq([older_dossier, recent_dossier].map(&:id)) }
      end

      context 'for en_construction_at column' do
        let(:column) { 'en_construction_at' }
        let!(:recent_dossier) { create(:dossier, :en_construction, procedure: procedure, en_construction_at: Time.zone.local(2018, 10, 17)) }
        let!(:older_dossier) { create(:dossier, :en_construction, procedure: procedure, en_construction_at: Time.zone.local(2013, 1, 1)) }

        it { is_expected.to eq([older_dossier, recent_dossier].map(&:id)) }
      end

      context 'for updated_at column' do
        let(:column) { 'updated_at' }
        let(:recent_dossier) { create(:dossier, procedure: procedure) }
        let(:older_dossier) { create(:dossier, procedure: procedure) }

        before do
          recent_dossier.touch(time: Time.zone.local(2018, 9, 25))
          older_dossier.touch(time: Time.zone.local(2018, 5, 13))
        end

        it { is_expected.to eq([older_dossier, recent_dossier].map(&:id)) }
      end
    end

    context 'for type_de_champ table' do
      context 'with no revisions' do
        let(:table) { 'type_de_champ' }
        let(:column) { procedure.active_revision.types_de_champ_public.first.stable_id.to_s }

        let(:beurre_dossier) { create(:dossier, procedure: procedure) }
        let(:tartine_dossier) { create(:dossier, procedure: procedure) }

        before do
          beurre_dossier.champs_public.first.update(value: 'beurre')
          tartine_dossier.champs_public.first.update(value: 'tartine')
        end

        context 'asc' do
          let(:order) { 'asc' }

          it { is_expected.to eq([beurre_dossier, tartine_dossier].map(&:id)) }
        end

        context 'desc' do
          let(:order) { 'desc' }

          it { is_expected.to eq([tartine_dossier, beurre_dossier].map(&:id)) }
        end
      end

      context 'with a revision adding a new type_de_champ' do
        let!(:tdc) { { type_champ: :text, libelle: 'nouveau champ' } }
        let(:table) { 'type_de_champ' }
        let(:column) { procedure.active_revision.types_de_champ_public.last.stable_id.to_s }

        let(:nothing_dossier) { create(:dossier, procedure: procedure) }
        let(:beurre_dossier) { create(:dossier, procedure: procedure) }
        let(:tartine_dossier) { create(:dossier, procedure: procedure) }

        before do
          nothing_dossier
          procedure.draft_revision.add_type_de_champ(tdc)
          procedure.publish_revision!
          beurre_dossier.champs_public.last.update(value: 'beurre')
          tartine_dossier.champs_public.last.update(value: 'tartine')
        end

        context 'asc' do
          let(:order) { 'asc' }
          it { is_expected.to eq([beurre_dossier, tartine_dossier, nothing_dossier].map(&:id)) }
        end

        context 'desc' do
          let(:order) { 'desc' }
          it { is_expected.to eq([nothing_dossier, tartine_dossier, beurre_dossier].map(&:id)) }
        end
      end
    end

    context 'for type_de_champ_private table' do
      context 'with no revisions' do
        let(:table) { 'type_de_champ_private' }
        let(:column) { procedure.active_revision.types_de_champ_private.first.stable_id.to_s }

        let(:biere_dossier) { create(:dossier, procedure: procedure) }
        let(:vin_dossier) { create(:dossier, procedure: procedure) }

        before do
          biere_dossier.champs_private.first.update(value: 'biere')
          vin_dossier.champs_private.first.update(value: 'vin')
        end

        context 'asc' do
          let(:order) { 'asc' }

          it { is_expected.to eq([biere_dossier, vin_dossier].map(&:id)) }
        end

        context 'desc' do
          let(:order) { 'desc' }

          it { is_expected.to eq([vin_dossier, biere_dossier].map(&:id)) }
        end
      end

      context 'with a revision adding a new type_de_champ' do
        let!(:tdc) { { type_champ: :text, private: true, libelle: 'nouveau champ' } }
        let(:table) { 'type_de_champ_private' }
        let(:column) { procedure.active_revision.types_de_champ_private.last.stable_id.to_s }

        let(:nothing_dossier) { create(:dossier, procedure: procedure) }
        let(:biere_dossier) { create(:dossier, procedure: procedure) }
        let(:vin_dossier) { create(:dossier, procedure: procedure) }

        before do
          nothing_dossier
          procedure.draft_revision.add_type_de_champ(tdc)
          procedure.publish_revision!
          biere_dossier.champs_private.last.update(value: 'biere')
          vin_dossier.champs_private.last.update(value: 'vin')
        end

        context 'asc' do
          let(:order) { 'asc' }
          it { is_expected.to eq([biere_dossier, vin_dossier, nothing_dossier].map(&:id)) }
        end

        context 'desc' do
          let(:order) { 'desc' }
          it { is_expected.to eq([nothing_dossier, vin_dossier, biere_dossier].map(&:id)) }
        end
      end
    end

    context 'for individual table' do
      let(:table) { 'individual' }
      let(:order) { 'asc' } # Desc works the same, no extra test required

      let(:procedure) { create(:procedure, :for_individual) }

      let!(:first_dossier) { create(:dossier, procedure: procedure, individual: build(:individual, gender: 'M', prenom: 'Alain', nom: 'Antonelli')) }
      let!(:last_dossier) { create(:dossier, procedure: procedure, individual: build(:individual, gender: 'Mme', prenom: 'Zora', nom: 'Zemmour')) }

      context 'for gender column' do
        let(:column) { 'gender' }

        it { is_expected.to eq([first_dossier, last_dossier].map(&:id)) }
      end

      context 'for prenom column' do
        let(:column) { 'prenom' }

        it { is_expected.to eq([first_dossier, last_dossier].map(&:id)) }
      end

      context 'for nom column' do
        let(:column) { 'nom' }

        it { is_expected.to eq([first_dossier, last_dossier].map(&:id)) }
      end
    end

    context 'for followers_instructeurs table' do
      let(:table) { 'followers_instructeurs' }
      let(:order) { 'asc' } # Desc works the same, no extra test required

      let!(:dossier_z) { create(:dossier, :en_construction, procedure: procedure) }
      let!(:dossier_a) { create(:dossier, :en_construction, procedure: procedure) }
      let!(:dossier_without_instructeur) { create(:dossier, :en_construction, procedure: procedure) }

      before do
        create(:follow, dossier: dossier_z, instructeur: create(:instructeur, email: 'zythum@exemple.fr'))
        create(:follow, dossier: dossier_a, instructeur: create(:instructeur, email: 'abaca@exemple.fr'))
        create(:follow, dossier: dossier_a, instructeur: create(:instructeur, email: 'abaca2@exemple.fr'))
      end

      context 'for email column' do
        let(:column) { 'email' }

        it { is_expected.to eq([dossier_a, dossier_z, dossier_without_instructeur].map(&:id)) }
      end
    end

    context 'for other tables' do
      # All other columns and tables work the same so it’s ok to test only one
      let(:table) { 'etablissement' }
      let(:column) { 'code_postal' }
      let(:order) { 'asc' } # Desc works the same, no extra test required

      let!(:huitieme_dossier) { create(:dossier, procedure: procedure, etablissement: create(:etablissement, code_postal: '75008')) }
      let!(:vingtieme_dossier) { create(:dossier, procedure: procedure, etablissement: create(:etablissement, code_postal: '75020')) }

      it { is_expected.to eq([huitieme_dossier, vingtieme_dossier].map(&:id)) }
    end
  end

  describe '#filtered_ids' do
    let(:procedure_presentation) { create(:procedure_presentation, assign_to: assign_to, filters: { "suivis" => filter }) }

    subject { procedure_presentation.filtered_ids(procedure.dossiers.joins(:user), 'suivis') }

    context 'for self table' do
      context 'for created_at column' do
        let(:filter) { [{ 'table' => 'self', 'column' => 'created_at', 'value' => '18/9/2018' }] }

        let!(:kept_dossier) { create(:dossier, procedure: procedure, created_at: Time.zone.local(2018, 9, 18, 14, 28)) }
        let!(:discarded_dossier) { create(:dossier, procedure: procedure, created_at: Time.zone.local(2018, 9, 17, 23, 59)) }

        it { is_expected.to contain_exactly(kept_dossier.id) }
      end

      context 'for en_construction_at column' do
        let(:filter) { [{ 'table' => 'self', 'column' => 'en_construction_at', 'value' => '17/10/2018' }] }

        let!(:kept_dossier) { create(:dossier, :en_construction, procedure: procedure, en_construction_at: Time.zone.local(2018, 10, 17)) }
        let!(:discarded_dossier) { create(:dossier, :en_construction, procedure: procedure, en_construction_at: Time.zone.local(2013, 1, 1)) }

        it { is_expected.to contain_exactly(kept_dossier.id) }
      end

      context 'for updated_at column' do
        let(:filter) { [{ 'table' => 'self', 'column' => 'updated_at', 'value' => '18/9/2018' }] }

        let(:kept_dossier) { create(:dossier, procedure: procedure) }
        let(:discarded_dossier) { create(:dossier, procedure: procedure) }

        before do
          kept_dossier.touch(time: Time.zone.local(2018, 9, 18, 14, 28))
          discarded_dossier.touch(time: Time.zone.local(2018, 9, 17, 23, 59))
        end

        it { is_expected.to contain_exactly(kept_dossier.id) }
      end

      context 'for updated_since column' do
        let(:filter) { [{ 'table' => 'self', 'column' => 'updated_since', 'value' => '18/9/2018' }] }

        let(:kept_dossier) { create(:dossier, procedure: procedure) }
        let(:later_dossier) { create(:dossier, procedure: procedure) }
        let(:discarded_dossier) { create(:dossier, procedure: procedure) }

        before do
          kept_dossier.touch(time: Time.zone.local(2018, 9, 18, 14, 28))
          later_dossier.touch(time: Time.zone.local(2018, 9, 19, 14, 28))
          discarded_dossier.touch(time: Time.zone.local(2018, 9, 17, 14, 28))
        end

        it { is_expected.to match_array([kept_dossier.id, later_dossier.id]) }
      end

      context 'ignore time of day' do
        let(:filter) { [{ 'table' => 'self', 'column' => 'en_construction_at', 'value' => '17/10/2018 19:30' }] }

        let!(:kept_dossier) { create(:dossier, :en_construction, procedure: procedure, en_construction_at: Time.zone.local(2018, 10, 17, 15, 56)) }
        let!(:discarded_dossier) { create(:dossier, :en_construction, procedure: procedure, en_construction_at: Time.zone.local(2018, 10, 18, 5, 42)) }

        it { is_expected.to contain_exactly(kept_dossier.id) }
      end

      context 'for a malformed date' do
        context 'when its a string' do
          let(:filter) { [{ 'table' => 'self', 'column' => 'updated_at', 'value' => 'malformed date' }] }

          it { is_expected.to match([]) }
        end

        context 'when its a number' do
          let(:filter) { [{ 'table' => 'self', 'column' => 'updated_at', 'value' => '177500' }] }

          it { is_expected.to match([]) }
        end
      end

      context 'with multiple search values' do
        let(:filter) do
          [
            { 'table' => 'self', 'column' => 'en_construction_at', 'value' => '17/10/2018' },
            { 'table' => 'self', 'column' => 'en_construction_at', 'value' => '19/10/2018' }
          ]
        end

        let!(:kept_dossier) { create(:dossier, :en_construction, procedure: procedure, en_construction_at: Time.zone.local(2018, 10, 17)) }
        let!(:other_kept_dossier) { create(:dossier, :en_construction, procedure: procedure, en_construction_at: Time.zone.local(2018, 10, 19)) }
        let!(:discarded_dossier) { create(:dossier, :en_construction, procedure: procedure, en_construction_at: Time.zone.local(2013, 1, 1)) }

        it 'returns every dossier that matches any of the search criteria for a given column' do
          is_expected.to contain_exactly(kept_dossier.id, other_kept_dossier.id)
        end
      end

      context 'with multiple state filters' do
        let(:filter) do
          [
            { 'table' => 'self', 'column' => 'state', 'value' => 'en_construction' },
            { 'table' => 'self', 'column' => 'state', 'value' => 'en_instruction' }
          ]
        end

        let!(:kept_dossier) { create(:dossier, :en_construction, procedure: procedure) }
        let!(:other_kept_dossier) { create(:dossier, :en_instruction, procedure: procedure) }
        let!(:discarded_dossier) { create(:dossier, :accepte, procedure: procedure) }

        it 'returns every dossier that matches any of the search criteria for a given column' do
          is_expected.to contain_exactly(kept_dossier.id, other_kept_dossier.id)
        end
      end
    end

    context 'for type_de_champ table' do
      let(:filter) { [{ 'table' => 'type_de_champ', 'column' => type_de_champ.stable_id.to_s, 'value' => 'keep' }] }

      let(:kept_dossier) { create(:dossier, procedure: procedure) }
      let(:discarded_dossier) { create(:dossier, procedure: procedure) }
      let(:type_de_champ) { procedure.active_revision.types_de_champ_public.first }

      context 'with single value' do
        before do
          kept_dossier.champs_public.find_by(type_de_champ: type_de_champ).update(value: 'keep me')
          discarded_dossier.champs_public.find_by(type_de_champ: type_de_champ).update(value: 'discard me')
        end

        it { is_expected.to contain_exactly(kept_dossier.id) }
      end

      context 'with multiple search values' do
        let(:filter) do
          [
            { 'table' => 'type_de_champ', 'column' => type_de_champ.stable_id.to_s, 'value' => 'keep' },
            { 'table' => 'type_de_champ', 'column' => type_de_champ.stable_id.to_s, 'value' => 'and' }
          ]
        end

        let(:other_kept_dossier) { create(:dossier, procedure: procedure) }

        before do
          kept_dossier.champs_public.find_by(type_de_champ: type_de_champ).update(value: 'keep me')
          discarded_dossier.champs_public.find_by(type_de_champ: type_de_champ).update(value: 'discard me')
          other_kept_dossier.champs_public.find_by(type_de_champ: type_de_champ).update(value: 'and me too')
        end

        it 'returns every dossier that matches any of the search criteria for a given column' do
          is_expected.to contain_exactly(kept_dossier.id, other_kept_dossier.id)
        end
      end

      context 'with yes_no type_de_champ' do
        let(:filter) { [{ 'table' => 'type_de_champ', 'column' => type_de_champ.stable_id.to_s, 'value' => 'true' }] }
        let(:procedure) { create(:procedure, :with_yes_no) }

        before do
          kept_dossier.champs_public.find_by(type_de_champ: type_de_champ).update(value: 'true')
          discarded_dossier.champs_public.find_by(type_de_champ: type_de_champ).update(value: 'false')
        end

        it { is_expected.to contain_exactly(kept_dossier.id) }
      end
    end

    context 'for type_de_champ_private table' do
      let(:filter) { [{ 'table' => 'type_de_champ_private', 'column' => type_de_champ_private.stable_id.to_s, 'value' => 'keep' }] }

      let(:kept_dossier) { create(:dossier, procedure: procedure) }
      let(:discarded_dossier) { create(:dossier, procedure: procedure) }
      let(:type_de_champ_private) { procedure.active_revision.types_de_champ_private.first }

      before do
        kept_dossier.champs_private.find_by(type_de_champ: type_de_champ_private).update(value: 'keep me')
        discarded_dossier.champs_private.find_by(type_de_champ: type_de_champ_private).update(value: 'discard me')
      end

      it { is_expected.to contain_exactly(kept_dossier.id) }

      context 'with multiple search values' do
        let(:filter) do
          [
            { 'table' => 'type_de_champ_private', 'column' => type_de_champ_private.stable_id.to_s, 'value' => 'keep' },
            { 'table' => 'type_de_champ_private', 'column' => type_de_champ_private.stable_id.to_s, 'value' => 'and' }
          ]
        end

        let(:other_kept_dossier) { create(:dossier, procedure: procedure) }

        before do
          other_kept_dossier.champs_private.find_by(type_de_champ: type_de_champ_private).update(value: 'and me too')
        end

        it 'returns every dossier that matches any of the search criteria for a given column' do
          is_expected.to contain_exactly(kept_dossier.id, other_kept_dossier.id)
        end
      end
    end

    context 'for etablissement table' do
      context 'for entreprise_date_creation column' do
        let(:filter) { [{ 'table' => 'etablissement', 'column' => 'entreprise_date_creation', 'value' => '21/6/2018' }] }

        let!(:kept_dossier) { create(:dossier, procedure: procedure, etablissement: create(:etablissement, entreprise_date_creation: Time.zone.local(2018, 6, 21))) }
        let!(:discarded_dossier) { create(:dossier, procedure: procedure, etablissement: create(:etablissement, entreprise_date_creation: Time.zone.local(2008, 6, 21))) }

        it { is_expected.to contain_exactly(kept_dossier.id) }

        context 'with multiple search values' do
          let(:filter) do
            [
              { 'table' => 'etablissement', 'column' => 'entreprise_date_creation', 'value' => '21/6/2016' },
              { 'table' => 'etablissement', 'column' => 'entreprise_date_creation', 'value' => '21/6/2018' }
            ]
          end

          let!(:other_kept_dossier) { create(:dossier, procedure: procedure, etablissement: create(:etablissement, entreprise_date_creation: Time.zone.local(2016, 6, 21))) }

          it 'returns every dossier that matches any of the search criteria for a given column' do
            is_expected.to contain_exactly(kept_dossier.id, other_kept_dossier.id)
          end
        end
      end

      context 'for code_postal column' do
        # All columns except entreprise_date_creation work exacly the same, just testing one

        let(:filter) { [{ 'table' => 'etablissement', 'column' => 'code_postal', 'value' => '75017' }] }

        let!(:kept_dossier) { create(:dossier, procedure: procedure, etablissement: create(:etablissement, code_postal: '75017')) }
        let!(:discarded_dossier) { create(:dossier, procedure: procedure, etablissement: create(:etablissement, code_postal: '25000')) }

        it { is_expected.to contain_exactly(kept_dossier.id) }

        context 'with multiple search values' do
          let(:filter) do
            [
              { 'table' => 'etablissement', 'column' => 'code_postal', 'value' => '75017' },
              { 'table' => 'etablissement', 'column' => 'code_postal', 'value' => '88100' }
            ]
          end

          let!(:other_kept_dossier) { create(:dossier, procedure: procedure, etablissement: create(:etablissement, code_postal: '88100')) }

          it 'returns every dossier that matches any of the search criteria for a given column' do
            is_expected.to contain_exactly(kept_dossier.id, other_kept_dossier.id)
          end
        end
      end
    end

    context 'for user table' do
      let(:filter) { [{ 'table' => 'user', 'column' => 'email', 'value' => 'keepmail' }] }

      let!(:kept_dossier) { create(:dossier, procedure: procedure, user: create(:user, email: 'me@keepmail.com')) }
      let!(:discarded_dossier) { create(:dossier, procedure: procedure, user: create(:user, email: 'me@discard.com')) }

      it { is_expected.to contain_exactly(kept_dossier.id) }

      context 'with multiple search values' do
        let(:filter) do
          [
            { 'table' => 'user', 'column' => 'email', 'value' => 'keepmail' },
            { 'table' => 'user', 'column' => 'email', 'value' => 'beta.gouv.fr' }
          ]
        end

        let!(:other_kept_dossier) { create(:dossier, procedure: procedure, user: create(:user, email: 'bazinga@beta.gouv.fr')) }

        it 'returns every dossier that matches any of the search criteria for a given column' do
          is_expected.to contain_exactly(kept_dossier.id, other_kept_dossier.id)
        end
      end
    end

    context 'for individual table' do
      let(:procedure) { create(:procedure, :for_individual) }
      let!(:kept_dossier) { create(:dossier, procedure: procedure, individual: build(:individual, gender: 'Mme', prenom: 'Josephine', nom: 'Baker')) }
      let!(:discarded_dossier) { create(:dossier, procedure: procedure, individual: build(:individual, gender: 'M', prenom: 'Jean', nom: 'Tremblay')) }

      context 'for gender column' do
        let(:filter) { [{ 'table' => 'individual', 'column' => 'gender', 'value' => 'Mme' }] }

        it { is_expected.to contain_exactly(kept_dossier.id) }
      end

      context 'for prenom column' do
        let(:filter) { [{ 'table' => 'individual', 'column' => 'prenom', 'value' => 'Josephine' }] }

        it { is_expected.to contain_exactly(kept_dossier.id) }
      end

      context 'for nom column' do
        let(:filter) { [{ 'table' => 'individual', 'column' => 'nom', 'value' => 'Baker' }] }

        it { is_expected.to contain_exactly(kept_dossier.id) }
      end

      context 'with multiple search values' do
        let(:filter) do
          [
            { 'table' => 'individual', 'column' => 'prenom', 'value' => 'Josephine' },
            { 'table' => 'individual', 'column' => 'prenom', 'value' => 'Romuald' }
          ]
        end

        let!(:other_kept_dossier) { create(:dossier, procedure: procedure, individual: build(:individual, gender: 'M', prenom: 'Romuald', nom: 'Pistis')) }

        it 'returns every dossier that matches any of the search criteria for a given column' do
          is_expected.to contain_exactly(kept_dossier.id, other_kept_dossier.id)
        end
      end
    end

    context 'for followers_instructeurs table' do
      let(:filter) { [{ 'table' => 'followers_instructeurs', 'column' => 'email', 'value' => 'keepmail' }] }

      let!(:kept_dossier) { create(:dossier, procedure: procedure) }
      let!(:discarded_dossier) { create(:dossier, procedure: procedure) }

      before do
        create(:follow, dossier: kept_dossier, instructeur: create(:instructeur, email: 'me@keepmail.com'))
        create(:follow, dossier: discarded_dossier, instructeur: create(:instructeur, email: 'me@discard.com'))
      end

      it { is_expected.to contain_exactly(kept_dossier.id) }

      context 'with multiple search values' do
        let(:filter) do
          [
            { 'table' => 'followers_instructeurs', 'column' => 'email', 'value' => 'keepmail' },
            { 'table' => 'followers_instructeurs', 'column' => 'email', 'value' => 'beta.gouv.fr' }
          ]
        end

        let(:other_kept_dossier) { create(:dossier, procedure: procedure) }

        before do
          create(:follow, dossier: other_kept_dossier, instructeur: create(:instructeur, email: 'bazinga@beta.gouv.fr'))
        end

        it 'returns every dossier that matches any of the search criteria for a given column' do
          is_expected.to contain_exactly(kept_dossier.id, other_kept_dossier.id)
        end
      end
    end

    context 'for groupe_instructeur table' do
      let(:filter) { [{ 'table' => 'groupe_instructeur', 'column' => 'id', 'value' => procedure.defaut_groupe_instructeur.id.to_s }] }

      let!(:gi_2) { procedure.groupe_instructeurs.create(label: 'gi2') }
      let!(:gi_3) { procedure.groupe_instructeurs.create(label: 'gi3') }

      let!(:kept_dossier) { create(:dossier, :en_construction, procedure: procedure) }
      let!(:discarded_dossier) { create(:dossier, :en_construction, procedure: procedure, groupe_instructeur: gi_2) }

      it { is_expected.to contain_exactly(kept_dossier.id) }

      context 'with multiple search values' do
        let(:filter) do
          [
            { 'table' => 'groupe_instructeur', 'column' => 'id', 'value' => procedure.defaut_groupe_instructeur.id.to_s },
            { 'table' => 'groupe_instructeur', 'column' => 'id', 'value' => gi_3.id.to_s }
          ]
        end

        let!(:other_kept_dossier) { create(:dossier, procedure: procedure, groupe_instructeur: gi_3) }

        it 'returns every dossier that matches any of the search criteria for a given column' do
          is_expected.to contain_exactly(kept_dossier.id, other_kept_dossier.id)
        end
      end
    end
  end

  describe "#human_value_for_filter" do
    let(:filters) { { "suivis" => [{ "label" => "label1", "table" => "type_de_champ", "column" => first_type_de_champ_id, "value" => "true" }] } }

    subject { procedure_presentation.human_value_for_filter(procedure_presentation.filters["suivis"].first) }

    context 'when type_de_champ text' do
      it 'should passthrough value' do
        expect(subject).to eq("true")
      end
    end

    context 'when type_de_champ yes_no' do
      let(:procedure) { create(:procedure, :with_yes_no) }

      it 'should transform value' do
        expect(subject).to eq("oui")
      end
    end

    context 'when filter is state' do
      let(:filters) { { "suivis" => [{ "table" => "self", "column" => "state", "value" => "en_construction" }] } }

      it 'should get i18n value' do
        expect(subject).to eq("En construction")
      end
    end
  end

  describe "#add_filter" do
    let(:filters) { { "suivis" => [] } }

    context 'when type_de_champ yes_no' do
      let(:procedure) { create(:procedure, :with_yes_no) }

      it 'should downcase and transform value' do
        procedure_presentation.add_filter("suivis", "type_de_champ/#{first_type_de_champ_id}", "Oui")

        expect(procedure_presentation.filters).to eq({
          "suivis" =>
                    [
                      { "label" => first_type_de_champ.libelle, "table" => "type_de_champ", "column" => first_type_de_champ_id, "value" => "true" }
                    ]
        })
      end
    end

    context 'when type_de_champ text' do
      let(:filters) { { "suivis" => [] } }

      it 'should passthrough value' do
        procedure_presentation.add_filter("suivis", "type_de_champ/#{first_type_de_champ_id}", "Oui")

        expect(procedure_presentation.filters).to eq({
          "suivis" => [
            { "label" => first_type_de_champ.libelle, "table" => "type_de_champ", "column" => first_type_de_champ_id, "value" => "Oui" }
          ]
        })
      end
    end
  end

  describe '#filtered_sorted_ids' do
    let(:dossier_1) { create(:dossier) }
    let(:dossier_2) { create(:dossier) }
    let(:dossier_3) { create(:dossier) }
    let(:dossiers) { Dossier.where(id: [dossier_1, dossier_2, dossier_3].map(&:id)) }

    let(:sorted_ids) { [dossier_2, dossier_3, dossier_1].map(&:id) }

    subject { procedure_presentation.filtered_sorted_ids(dossiers, 'tous') }

    before do
      expect(procedure_presentation).to receive(:sorted_ids).and_return(sorted_ids)
    end

    it { is_expected.to eq(sorted_ids) }

    context 'when a filter is present' do
      let(:filtered_ids) { [dossier_1, dossier_2, dossier_3].map(&:id) }

      before do
        procedure_presentation.filters['tous'] = 'some_filter'
        expect(procedure_presentation).to receive(:filtered_ids).and_return(filtered_ids)
      end

      it { is_expected.to eq(sorted_ids) }
    end
  end
end
