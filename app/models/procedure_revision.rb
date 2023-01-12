# == Schema Information
#
# Table name: procedure_revisions
#
#  id                           :bigint           not null, primary key
#  migrated_champ_routage       :boolean
#  published_at                 :datetime
#  created_at                   :datetime         not null
#  updated_at                   :datetime         not null
#  attestation_template_id      :bigint
#  dossier_submitted_message_id :bigint
#  procedure_id                 :bigint           not null
#
class ProcedureRevision < ApplicationRecord
  self.implicit_order_column = :created_at
  belongs_to :procedure, -> { with_discarded }, inverse_of: :revisions, optional: false
  belongs_to :dossier_submitted_message, inverse_of: :revisions, optional: true, dependent: :destroy

  has_many :dossiers, inverse_of: :revision, foreign_key: :revision_id

  has_many :revision_types_de_champ, -> { order(:position, :id) }, class_name: 'ProcedureRevisionTypeDeChamp', foreign_key: :revision_id, dependent: :destroy, inverse_of: :revision
  has_many :revision_types_de_champ_public, -> { root.public_only.ordered }, class_name: 'ProcedureRevisionTypeDeChamp', foreign_key: :revision_id, dependent: :destroy, inverse_of: :revision
  has_many :revision_types_de_champ_private, -> { root.private_only.ordered }, class_name: 'ProcedureRevisionTypeDeChamp', foreign_key: :revision_id, dependent: :destroy, inverse_of: :revision
  has_many :types_de_champ, through: :revision_types_de_champ, source: :type_de_champ
  has_many :types_de_champ_public, through: :revision_types_de_champ_public, source: :type_de_champ
  has_many :types_de_champ_private, through: :revision_types_de_champ_private, source: :type_de_champ

  has_one :draft_procedure, -> { with_discarded }, class_name: 'Procedure', foreign_key: :draft_revision_id, dependent: :nullify, inverse_of: :draft_revision
  has_one :published_procedure, -> { with_discarded }, class_name: 'Procedure', foreign_key: :published_revision_id, dependent: :nullify, inverse_of: :published_revision

  scope :ordered, -> { order(:created_at) }

  validate :conditions_are_valid?

  def build_champs_public
    # reload: it can be out of sync in test if some tdcs are added wihtout using add_tdc
    types_de_champ_public.reload.map { |tdc| tdc.build_champ(revision: self) }
  end

  def build_champs_private
    # reload: it can be out of sync in test if some tdcs are added wihtout using add_tdc
    types_de_champ_private.reload.map { |tdc| tdc.build_champ(revision: self) }
  end

  def add_type_de_champ(params)
    parent_stable_id = params.delete(:parent_stable_id)
    parent_coordinate, _ = coordinate_and_tdc(parent_stable_id)
    parent_id = parent_coordinate&.id

    after_stable_id = params.delete(:after_stable_id)
    after_coordinate, _ = coordinate_and_tdc(after_stable_id)

    # the collection is orderd by (position, id), so we can use after_coordinate.position
    # if not present, a big number is used to ensure the element is at the tail
    position = (after_coordinate&.position) || 100_000

    tdc = TypeDeChamp.new(params)
    if tdc.save
      h = { type_de_champ: tdc, parent_id: parent_id, position: position }
      coordinate = revision_types_de_champ.create!(h)

      renumber(coordinate.reload.siblings)
    end

    # they are not aware of the addition
    types_de_champ_public.reset
    types_de_champ_private.reset

    tdc
  rescue => e
    TypeDeChamp.new.tap { |tdc| tdc.errors.add(:base, e.message) }
  end

  def find_and_ensure_exclusive_use(stable_id)
    coordinate, tdc = coordinate_and_tdc(stable_id)

    if tdc.only_present_on_draft?
      tdc
    else
      replace_type_de_champ_by_clone(coordinate)
    end
  end

  def move_type_de_champ(stable_id, position)
    coordinate, _ = coordinate_and_tdc(stable_id)

    siblings = coordinate.siblings.to_a

    siblings.insert(position, siblings.delete_at(siblings.index(coordinate)))

    renumber(siblings)
    coordinate.reload

    coordinate
  end

  def remove_type_de_champ(stable_id)
    coordinate, tdc = coordinate_and_tdc(stable_id)

    # in case of replay
    return nil if coordinate.nil?

    children = children_of(tdc).to_a
    coordinate.destroy

    children.each(&:destroy_if_orphan)
    tdc.destroy_if_orphan

    # they are not aware of the removal
    types_de_champ_public.reset
    types_de_champ_private.reset

    renumber(coordinate.siblings)

    coordinate
  end

  def move_up_type_de_champ(stable_id)
    coordinate, _ = coordinate_and_tdc(stable_id)

    if coordinate.position > 0
      move_type_de_champ(stable_id, coordinate.position - 1)
    else
      coordinate
    end
  end

  def move_down_type_de_champ(stable_id)
    coordinate, _ = coordinate_and_tdc(stable_id)

    move_type_de_champ(stable_id, coordinate.position + 1)
  end

  def draft?
    procedure.draft_revision == self
  end

  def locked?
    !draft?
  end

  def different_from?(revision)
    revision_types_de_champ != revision.revision_types_de_champ
  end

  def compare(revision)
    changes = []
    changes += compare_revision_types_de_champ(revision_types_de_champ, revision.revision_types_de_champ)
    changes
  end

  def new_dossier
    Dossier.new(
      revision: self,
      champs_public: build_champs_public,
      champs_private: build_champs_private,
      groupe_instructeur: procedure.defaut_groupe_instructeur
    )
  end

  def dossier_for_preview(user)
    dossier = Dossier
      .create_with(groupe_instructeur: procedure.defaut_groupe_instructeur_for_new_dossier)
      .find_or_initialize_by(revision: self, user: user, for_procedure_preview: true, state: Dossier.states.fetch(:brouillon))

    if dossier.new_record?
      dossier.build_default_individual
      dossier.save!
    end

    dossier
  end

  def children_of(tdc)
    parent_coordinate_id = revision_types_de_champ.where(type_de_champ: tdc).select(:id)

    types_de_champ
      .where(procedure_revision_types_de_champ: { parent_id: parent_coordinate_id })
      .order("procedure_revision_types_de_champ.position")
  end

  def remove_children_of(tdc)
    children_of(tdc).each do |child|
      remove_type_de_champ(child.stable_id)
    end
  end

  # Estimated duration to fill the form, in seconds.
  #
  # If the revision is locked (i.e. published), the result is cached (because type de champs can no longer be mutated).
  def estimated_fill_duration
    Rails.cache.fetch("#{cache_key_with_version}/estimated_fill_duration", expires_in: 12.hours, force: !locked?) do
      compute_estimated_fill_duration
    end
  end

  def coordinate_for(tdc)
    revision_types_de_champ.find_by!(type_de_champ: tdc)
  end

  def carte?
    types_de_champ_public.any?(&:carte?)
  end

  private

  def compute_estimated_fill_duration
    types_de_champ_public.sum do |tdc|
      next tdc.estimated_read_duration unless tdc.fillable?

      duration = tdc.estimated_read_duration + tdc.estimated_fill_duration(self)
      duration /= 2 unless tdc.mandatory?

      duration
    end
  end

  def children_types_de_champ_as_json(tdcs_as_json, parent_tdcs)
    parent_tdcs.each do |parent_tdc|
      tdc_as_json = tdcs_as_json.find { |json| json["id"] == parent_tdc.stable_id }
      tdc_as_json&.merge!(types_de_champ: children_of(parent_tdc).includes(piece_justificative_template_attachment: :blob).map(&:as_json_for_editor))
    end
  end

  def coordinate_and_tdc(stable_id)
    return [nil, nil] if stable_id.blank?

    coordinate = revision_types_de_champ
      .joins(:type_de_champ)
      .find_by(type_de_champ: { stable_id: stable_id })

    [coordinate, coordinate&.type_de_champ]
  end

  def renumber(siblings)
    siblings.to_a.compact.each.with_index do |sibling, position|
      sibling.update_column(:position, position)
    end
  end

  def compare_revision_types_de_champ(from_coordinates, to_coordinates)
    if from_coordinates == to_coordinates
      []
    else
      from_h = from_coordinates.index_by(&:stable_id)
      to_h = to_coordinates.index_by(&:stable_id)

      from_sids = from_h.keys
      to_sids = to_h.keys

      removed = (from_sids - to_sids).map { ProcedureRevisionChange::RemoveChamp.new(from_h[_1]) }
      added = (to_sids - from_sids).map { ProcedureRevisionChange::AddChamp.new(to_h[_1]) }

      kept = from_sids.intersection(to_sids)

      moved = kept
        .map { [from_h[_1], to_h[_1]] }
        .filter { |from, to| from.position != to.position }
        .map { |from, to| ProcedureRevisionChange::MoveChamp.new(from, from.position, to.position) }

      changed = kept
        .map { [from_h[_1], to_h[_1]] }
        .flat_map { |from, to| compare_type_de_champ(from.type_de_champ, to.type_de_champ, from_coordinates, to_coordinates) }

      (removed + added + moved + changed).sort_by { _1.op == :remove ? from_sids[_1.stable_id] : to_sids[_1.stable_id] }
    end
  end

  def compare_type_de_champ(from_type_de_champ, to_type_de_champ, from_coordinates, to_coordinates)
    changes = []
    if from_type_de_champ.type_champ != to_type_de_champ.type_champ
      changes << ProcedureRevisionChange::UpdateChamp.new(from_type_de_champ,
        :type_champ,
        from_type_de_champ.type_champ,
        to_type_de_champ.type_champ)
    end
    if from_type_de_champ.libelle != to_type_de_champ.libelle
      changes << ProcedureRevisionChange::UpdateChamp.new(from_type_de_champ,
        :libelle,
        from_type_de_champ.libelle,
        to_type_de_champ.libelle)
    end
    if from_type_de_champ.collapsible_explanation_enabled? != to_type_de_champ.collapsible_explanation_enabled?
      changes << ProcedureRevisionChange::UpdateChamp.new(from_type_de_champ,
        :collapsible_explanation_enabled,
        from_type_de_champ.collapsible_explanation_enabled?,
        to_type_de_champ.collapsible_explanation_enabled?)
    end
    if from_type_de_champ.collapsible_explanation_text != to_type_de_champ.collapsible_explanation_text
      changes << ProcedureRevisionChange::UpdateChamp.new(from_type_de_champ,
        :collapsible_explanation_text,
        from_type_de_champ.collapsible_explanation_text,
        to_type_de_champ.collapsible_explanation_text)
    end
    if from_type_de_champ.description != to_type_de_champ.description
      changes << ProcedureRevisionChange::UpdateChamp.new(from_type_de_champ,
        :description,
        from_type_de_champ.description,
        to_type_de_champ.description)
    end
    if from_type_de_champ.mandatory? != to_type_de_champ.mandatory?
      changes << ProcedureRevisionChange::UpdateChamp.new(from_type_de_champ,
        :mandatory,
        from_type_de_champ.mandatory?,
        to_type_de_champ.mandatory?)
    end

    if from_type_de_champ.condition != to_type_de_champ.condition
      changes << ProcedureRevisionChange::UpdateChamp.new(from_type_de_champ,
        :condition,
        from_type_de_champ.condition&.to_s(from_coordinates.map(&:type_de_champ)),
        to_type_de_champ.condition&.to_s(to_coordinates.map(&:type_de_champ)))
    end

    if to_type_de_champ.drop_down_list?
      if from_type_de_champ.drop_down_list_options != to_type_de_champ.drop_down_list_options
        changes << ProcedureRevisionChange::UpdateChamp.new(from_type_de_champ,
          :drop_down_options,
          from_type_de_champ.drop_down_list_options,
          to_type_de_champ.drop_down_list_options)
      end
      if to_type_de_champ.linked_drop_down_list?
        if from_type_de_champ.drop_down_secondary_libelle != to_type_de_champ.drop_down_secondary_libelle
          changes << ProcedureRevisionChange::UpdateChamp.new(from_type_de_champ,
            :drop_down_secondary_libelle,
            from_type_de_champ.drop_down_secondary_libelle,
            to_type_de_champ.drop_down_secondary_libelle)
        end
        if from_type_de_champ.drop_down_secondary_description != to_type_de_champ.drop_down_secondary_description
          changes << ProcedureRevisionChange::UpdateChamp.new(from_type_de_champ,
            :drop_down_secondary_description,
            from_type_de_champ.drop_down_secondary_description,
            to_type_de_champ.drop_down_secondary_description)
        end
      end
      if from_type_de_champ.drop_down_other? != to_type_de_champ.drop_down_other?
        changes << ProcedureRevisionChange::UpdateChamp.new(from_type_de_champ,
          :drop_down_other,
          from_type_de_champ.drop_down_other?,
          to_type_de_champ.drop_down_other?)
      end
    elsif to_type_de_champ.carte?
      if from_type_de_champ.carte_optional_layers != to_type_de_champ.carte_optional_layers
        changes << ProcedureRevisionChange::UpdateChamp.new(from_type_de_champ,
          :carte_layers,
          from_type_de_champ.carte_optional_layers,
          to_type_de_champ.carte_optional_layers)
      end
    elsif to_type_de_champ.piece_justificative?
      if from_type_de_champ.piece_justificative_template_checksum != to_type_de_champ.piece_justificative_template_checksum
        changes << ProcedureRevisionChange::UpdateChamp.new(from_type_de_champ,
          :piece_justificative_template,
          from_type_de_champ.piece_justificative_template_filename,
          to_type_de_champ.piece_justificative_template_filename)
      end
    end
    changes
  end

  def replace_type_de_champ_by_clone(coordinate)
    cloned_type_de_champ = coordinate.type_de_champ.deep_clone do |original, kopy|
      PiecesJustificativesService.clone_attachments(original, kopy)
    end
    coordinate.update!(type_de_champ: cloned_type_de_champ)
    cloned_type_de_champ
  end

  def conditions_are_valid?
    public_tdcs = types_de_champ_public.to_a

    public_tdcs
      .map.with_index
      .filter_map { |tdc, i| tdc.condition.present? ? [tdc, i] : nil }
      .map { |tdc, i| [tdc, tdc.condition.errors(public_tdcs.take(i))] }
      .filter { |_tdc, errors| errors.present? }
      .each { |tdc, message| errors.add(:condition, message, type_de_champ: tdc) }
  end
end
