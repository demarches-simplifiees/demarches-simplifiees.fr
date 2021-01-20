# == Schema Information
#
# Table name: procedure_revisions
#
#  id           :bigint           not null, primary key
#  published_at :datetime
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  procedure_id :bigint           not null
#
class ProcedureRevision < ApplicationRecord
  self.implicit_order_column = :created_at
  belongs_to :procedure, -> { with_discarded }, inverse_of: :revisions, optional: false

  has_many :dossiers, inverse_of: :revision, foreign_key: :revision_id

  has_many :revision_types_de_champ, -> { public_only.ordered }, class_name: 'ProcedureRevisionTypeDeChamp', foreign_key: :revision_id, dependent: :destroy, inverse_of: :revision
  has_many :revision_types_de_champ_private, -> { private_only.ordered }, class_name: 'ProcedureRevisionTypeDeChamp', foreign_key: :revision_id, dependent: :destroy, inverse_of: :revision
  has_many :types_de_champ, through: :revision_types_de_champ, source: :type_de_champ
  has_many :types_de_champ_private, through: :revision_types_de_champ_private, source: :type_de_champ

  has_many :owned_types_de_champ, class_name: 'TypeDeChamp', foreign_key: :revision_id, dependent: :destroy, inverse_of: :revision
  has_one :draft_procedure, -> { with_discarded }, class_name: 'Procedure', foreign_key: :draft_revision_id, dependent: :nullify, inverse_of: :draft_revision
  has_one :published_procedure, -> { with_discarded }, class_name: 'Procedure', foreign_key: :published_revision_id, dependent: :nullify, inverse_of: :published_revision

  def build_champs
    types_de_champ.map(&:build_champ)
  end

  def build_champs_private
    types_de_champ_private.map(&:build_champ)
  end

  def add_type_de_champ(params)
    params[:revision] = self

    if params[:parent_id]
      find_or_clone_type_de_champ(params.delete(:parent_id))
        .types_de_champ
        .tap do |types_de_champ|
          params[:order_place] = types_de_champ.present? ? types_de_champ.last.order_place + 1 : 0
        end.create(params)
    elsif params[:private]
      types_de_champ_private.create(params)
    else
      types_de_champ.create(params)
    end
  end

  def find_or_clone_type_de_champ(id)
    type_de_champ = find_type_de_champ_by_id(id)

    if type_de_champ.revision == self
      type_de_champ
    elsif type_de_champ.parent.present?
      find_or_clone_type_de_champ(type_de_champ.parent.stable_id).types_de_champ.find_by!(stable_id: id)
    else
      revise_type_de_champ(type_de_champ)
    end
  end

  def move_type_de_champ(id, position)
    type_de_champ = find_type_de_champ_by_id(id)

    if type_de_champ.parent.present?
      repetition_type_de_champ = find_or_clone_type_de_champ(id).parent

      move_type_de_champ_hash(repetition_type_de_champ.types_de_champ.to_a, type_de_champ, position).each do |(id, position)|
        repetition_type_de_champ.types_de_champ.find(id).update!(order_place: position)
      end
    elsif type_de_champ.private?
      move_type_de_champ_hash(types_de_champ_private.to_a, type_de_champ, position).each do |(id, position)|
        revision_types_de_champ_private.find_by!(type_de_champ_id: id).update!(position: position)
      end
    else
      move_type_de_champ_hash(types_de_champ.to_a, type_de_champ, position).each do |(id, position)|
        revision_types_de_champ.find_by!(type_de_champ_id: id).update!(position: position)
      end
    end
  end

  def remove_type_de_champ(id)
    type_de_champ = find_type_de_champ_by_id(id)

    if type_de_champ.revision == self
      type_de_champ.destroy
    elsif type_de_champ.parent.present?
      find_or_clone_type_de_champ(id).destroy
    elsif type_de_champ.private?
      types_de_champ_private.delete(type_de_champ)
    else
      types_de_champ.delete(type_de_champ)
    end
  end

  def draft?
    procedure.draft_revision == self
  end

  def locked?
    !draft?
  end

  def changed?(revision)
    types_de_champ != revision.types_de_champ || types_de_champ_private != revision.types_de_champ_private
  end

  def compare(revision)
    changes = []
    changes += compare_types_de_champ(types_de_champ, revision.types_de_champ)
    changes += compare_types_de_champ(types_de_champ_private, revision.types_de_champ_private)
    changes
  end

  private

  def compare_types_de_champ(from_tdc, to_tdc)
    if from_tdc == to_tdc
      []
    else
      from_h = from_tdc.to_h { |tdc| [tdc.stable_id, tdc] }
      to_h = to_tdc.to_h { |tdc| [tdc.stable_id, tdc] }

      from_sids = from_h.keys
      to_sids = to_h.keys

      removed = (from_sids - to_sids).map do |sid|
        { op: :remove, label: from_h[sid].libelle, position: from_sids.index(sid) }
      end

      added = (to_sids - from_sids).map do |sid|
        { op: :add, label: to_h[sid].libelle, position: to_sids.index(sid) }
      end

      kept = from_sids.intersection(to_sids)

      moved = kept
        .map { |sid| [sid, from_sids.index(sid), to_sids.index(sid)] }
        .filter { |_, from_index, to_index| from_index != to_index }
        .map do |sid, from_index, to_index|
        { op: :move, label: from_h[sid].libelle, from: from_index, to: to_index, position: to_index }
      end

      changed = kept
        .map { |sid| [sid, from_h[sid], to_h[sid]] }
        .flat_map do |sid, from, to|
        compare_type_de_champ(from, to)
          .each { |h| h[:position] = to_sids.index(sid) }
      end

      (removed + added + moved + changed)
        .sort_by { |h| h[:position] }
        .each { |h| h.delete(:position) }
    end
  end

  def compare_type_de_champ(from_type_de_champ, to_type_de_champ)
    changes = []
    if from_type_de_champ.type_champ != to_type_de_champ.type_champ
      changes << {
        op: :update,
        attribute: :type_champ,
        label: from_type_de_champ.libelle,
        from: from_type_de_champ.type_champ,
        to: to_type_de_champ.type_champ
      }
    end
    if from_type_de_champ.libelle != to_type_de_champ.libelle
      changes << {
        op: :update,
        attribute: :libelle,
        label: from_type_de_champ.libelle,
        from: from_type_de_champ.libelle,
        to: to_type_de_champ.libelle
      }
    end
    if from_type_de_champ.description != to_type_de_champ.description
      changes << {
        op: :update,
        attribute: :description,
        label: from_type_de_champ.libelle,
        from: from_type_de_champ.description,
        to: to_type_de_champ.description
      }
    end
    if from_type_de_champ.mandatory? != to_type_de_champ.mandatory?
      changes << {
        op: :update,
        attribute: :mandatory,
        label: from_type_de_champ.libelle,
        from: from_type_de_champ.mandatory?,
        to: to_type_de_champ.mandatory?
      }
    end
    if to_type_de_champ.drop_down_list?
      if from_type_de_champ.drop_down_list_options != to_type_de_champ.drop_down_list_options
        changes << {
          op: :update,
          attribute: :drop_down_options,
          label: from_type_de_champ.libelle,
          from: from_type_de_champ.drop_down_list_options,
          to: to_type_de_champ.drop_down_list_options
        }
      end
    elsif to_type_de_champ.piece_justificative?
      if from_type_de_champ.piece_justificative_template_checksum != to_type_de_champ.piece_justificative_template_checksum
        changes << {
          op: :update,
          attribute: :piece_justificative_template,
          label: from_type_de_champ.libelle,
          from: from_type_de_champ.piece_justificative_template_filename,
          to: to_type_de_champ.piece_justificative_template_filename
        }
      end
    elsif to_type_de_champ.repetition?
      if from_type_de_champ.types_de_champ != to_type_de_champ.types_de_champ
        changes += compare_types_de_champ(from_type_de_champ.types_de_champ, to_type_de_champ.types_de_champ)
      end
    end
    changes
  end

  def revise_type_de_champ(type_de_champ)
    types_de_champ_association = type_de_champ.private? ? :revision_types_de_champ_private : :revision_types_de_champ
    association = send(types_de_champ_association).find_by!(type_de_champ: type_de_champ)
    cloned_type_de_champ = type_de_champ.deep_clone(include: [:types_de_champ], &type_de_champ.method(:clone_attachments))
    cloned_type_de_champ.revision = self
    association.update!(type_de_champ: cloned_type_de_champ)
    cloned_type_de_champ
  end

  def find_type_de_champ_by_id(id)
    types_de_champ.find_by(stable_id: id) ||
      types_de_champ_private.find_by(stable_id: id) ||
      types_de_champ_in_repetition.find_by!(stable_id: id)
  end

  def types_de_champ_in_repetition
    parent_ids = types_de_champ.repetition.ids + types_de_champ_private.repetition.ids
    TypeDeChamp.where(parent_id: parent_ids)
  end

  def move_type_de_champ_hash(types_de_champ, type_de_champ, new_index)
    old_index = types_de_champ.index(type_de_champ)

    if types_de_champ.delete_at(old_index)
      types_de_champ.insert(new_index, type_de_champ)
        .map.with_index do |type_de_champ, index|
          [type_de_champ.id, index]
        end
    else
      []
    end
  end
end
