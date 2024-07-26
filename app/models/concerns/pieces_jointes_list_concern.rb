module PiecesJointesListConcern
  extend ActiveSupport::Concern

  included do
    def public_wrapped_partionned_pjs
      pieces_jointes(public_only: true, wrap_with_parent: true)
        .partition { |(pj, _)| pj.condition.nil? }
    end

    def exportables_pieces_jointes
      pieces_jointes(exclude_titre_identite: true)
    end

    def exportables_pieces_jointes_for_all_versions
      pieces_jointes(
        exclude_titre_identite: true,
        revision: revisions
      ).sort_by { - _1.id }.uniq(&:stable_id)
    end

    def outdated_exportables_pieces_jointes
      exportables_pieces_jointes_for_all_versions - exportables_pieces_jointes
    end

    private

    def pieces_jointes(
      exclude_titre_identite: false,
      public_only: false,
      wrap_with_parent: false,
      revision: active_revision
    )
      coordinates = ProcedureRevisionTypeDeChamp.where(revision:)
        .includes(:type_de_champ, revision_types_de_champ: :type_de_champ)

      coordinates = coordinates.public_only if public_only

      type_champ = ['piece_justificative']
      type_champ << 'titre_identite' if !exclude_titre_identite

      coordinates = coordinates.where(types_de_champ: { type_champ: })

      return coordinates.map(&:type_de_champ) if !wrap_with_parent

      # we want pj in the form of [[pj1], [pj2, repetition], [pj3, repetition]]
      coordinates
        .map { |c| c.child? ? [c, c.parent] : [c] }
        .map { |a| a.map(&:type_de_champ) }
    end
  end
end
