# frozen_string_literal: true

describe Instructeurs::ProcedurePresentationController, type: :controller do
  describe '#update' do
    subject { patch :update, params: }

    let(:procedure) { create(:procedure) }
    let(:instructeur) { create(:instructeur) }
    let(:procedure_presentation) do
      groupe_instructeur = procedure.defaut_groupe_instructeur
      assign_to = create(:assign_to, instructeur:, groupe_instructeur:)
      assign_to.procedure_presentation_or_default_and_errors.first
    end
    let(:state_column) { procedure.dossier_state_column }

    let(:params) { { id: procedure_presentation.id }.merge(presentation_params) }

    context 'nominal case' do
      before { sign_in(instructeur.user) }

      let(:presentation_params) do
        {
          displayed_columns: [state_column.id],
          sorted_column: { order: 'asc', id: state_column.id },
          filters: [{ id: state_column.id, filter: 'en_construction' }],
          statut: 'tous'
        }
      end

      it 'updates the procedure_presentation' do
        expect(procedure_presentation.displayed_columns).to eq(procedure.default_displayed_columns)
        expect(procedure_presentation.sorted_column).to eq(procedure.default_sorted_column)
        expect(procedure_presentation.tous_filters).to eq([])

        subject
        expect(response).to redirect_to(instructeur_procedure_url(procedure))

        procedure_presentation.reload

        expect(procedure_presentation.displayed_columns).to eq([state_column])

        expect(procedure_presentation.sorted_column.column).to eq(state_column)
        expect(procedure_presentation.sorted_column.order).to eq('asc')

        filtered_column = FilteredColumn.new(column: state_column, filter: 'en_construction')
        expect(procedure_presentation.tous_filters).to eq([filtered_column])
      end
    end

    context 'with a wrong instructeur' do
      let(:another_instructeur) { create(:instructeur) }
      before { sign_in(another_instructeur.user) }

      let(:presentation_params) { { displayed_columns: [state_column.id] } }

      it 'does not update the procedure_presentation' do
        expect { subject }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context 'with an empty string in displayed_columns' do
      before { sign_in(instructeur.user) }

      let(:presentation_params) { { displayed_columns: [''] } }

      it 'removes the empty string' do
        subject
        expect(procedure_presentation.reload.displayed_columns).to eq([])
      end
    end

    context 'with an error in filters' do
      before { sign_in(instructeur.user) }

      let(:presentation_params) do
        { filters: [{ id: state_column.id, filter: '' }], statut: 'tous' }
      end

      it 'does not update the procedure_presentation' do
        subject

        expect(flash.alert).to include(/ne peut pas être vide/)
      end
    end
  end

  describe '#refresh_column_filter' do
    subject { post :refresh_column_filter, params: { id: procedure_presentation.id, format: :turbo_stream, filter: { id: column.id } } }

    render_views

    let(:procedure) { create(:procedure, :routee) }
    let(:instructeur) { create(:instructeur) }
    let!(:instructeur_procedure) { create(:instructeurs_procedure, instructeur:, procedure:) }
    let(:column) { procedure.find_column(label: "Groupe instructeur") }

    let(:procedure_presentation) do
      procedure.groupe_instructeurs.each { _1.add(instructeur) }
      instructeur.reload.assign_to.first.procedure_presentation_or_default_and_errors.first
    end

    before { sign_in(instructeur.user) }

    it 'refreshes the column filter' do
      subject

      expect(response).to be_successful
      procedure.groupe_instructeurs.each do |gi|
        expect(response.body).to include(gi.label)
      end
    end
  end

  describe '#add_filter' do
    subject { post :add_filter, params: }

    let(:procedure) { create(:procedure, types_de_champ_public: [{ type: :drop_down_list, libelle: 'Votre ville', options: ['Paris', 'Lyon', 'Marseille'] }]) }
    let(:instructeur) { create(:instructeur) }
    let(:procedure_presentation) do
      groupe_instructeur = procedure.defaut_groupe_instructeur
      assign_to = create(:assign_to, instructeur:, groupe_instructeur:)
      assign_to.procedure_presentation_or_default_and_errors.first
    end
    let(:column) { procedure.find_column(label: 'Votre ville') }

    before { sign_in(instructeur.user) }

    context 'nominal case' do
      let(:params) { { id: procedure_presentation.id, statut: 'tous', filter: { id: column.id, filter: { operator: 'in', value: ['Paris', 'Lyon'] } } } }

      it 'adds the filter' do
        subject

        expect(response).to redirect_to(instructeur_procedure_url(procedure))

        expect(procedure_presentation.reload.tous_filters).to eq([FilteredColumn.new(column:, filter: { operator: 'in', value: ['Paris', 'Lyon'] })])
      end
    end

    context 'when the column id is missing' do
      let(:params) { { id: procedure_presentation.id, statut: 'tous', filter: { filter: { operator: 'match', value: ['Paris'] } } } }

      it 'does not add the filter and sets a flash alert' do
        expect {
          subject
        }.not_to change { procedure_presentation.reload.tous_filters }

        expect(response).to redirect_to(instructeur_procedure_url(procedure))
        expect(flash.alert).to eq(I18n.t('views.instructeurs.dossiers.filters.missing_column'))
      end
    end
  end

  describe '#remove_filter' do
    subject { delete :remove_filter, params: }

    let(:procedure) { create(:procedure, types_de_champ_public: [{ type: :drop_down_list, libelle: 'Votre ville', options: ['Paris', 'Lyon', 'Marseille'] }]) }
    let(:instructeur) { create(:instructeur) }
    let(:procedure_presentation) do
      groupe_instructeur = procedure.defaut_groupe_instructeur
      assign_to = create(:assign_to, instructeur:, groupe_instructeur:)
      assign_to.procedure_presentation_or_default_and_errors.first
    end
    let(:column) { procedure.find_column(label: 'Votre ville') }

    before do
      sign_in(instructeur.user)
      procedure_presentation.update!(tous_filters: [FilteredColumn.new(column:, filter: { operator: 'in', value: ['Paris', 'Lyon'] })])
    end

    context 'nominal case' do
      let(:params) { { id: procedure_presentation.id, statut: 'tous', filter: { id: column.id, filter: { operator: 'in', value: ['Paris', 'Lyon'] } } } }

      it 'removes the filter' do
        subject

        expect(response).to redirect_to(instructeur_procedure_url(procedure))

        expect(procedure_presentation.reload.tous_filters).to eq([])
      end
    end
  end
end
