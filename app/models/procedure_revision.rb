class ProcedureRevision < ApplicationRecord
  belongs_to :procedure, -> { with_discarded }, inverse_of: :revisions

  has_many :procedure_revision_types_de_champ, -> { public_only.ordered }, dependent: :destroy, inverse_of: :procedure_revision
  has_many :procedure_revision_types_de_champ_private, -> { private_only.ordered }, class_name: 'ProcedureRevisionTypeDeChamp', dependent: :destroy, inverse_of: :procedure_revision
  has_many :types_de_champ, through: :procedure_revision_types_de_champ, source: :type_de_champ
  has_many :types_de_champ_private, through: :procedure_revision_types_de_champ_private, source: :type_de_champ

  def build_champs
    types_de_champ.map(&:build_champ)
  end

  def build_champs_private
    types_de_champ_private.map(&:build_champ)
  end

  def add_type_de_champ(params)
    if params[:parent_id]
      find_or_clone_type_de_champ(params.delete(:parent_id)).types_de_champ.create(params.merge(procedure_revision: self))
    elsif params[:private]
      types_de_champ_private.create(params.merge(procedure_revision: self))
    else
      types_de_champ.create(params.merge(procedure_revision: self))
    end
  end

  def find_or_clone_type_de_champ(id)
    type_de_champ = find_type_de_champ_by_id(id)

    if type_de_champ.procedure_revision == self
      type_de_champ
    elsif type_de_champ.parent.present?
      find_or_clone_type_de_champ(type_de_champ.parent.stable_id).types_de_champ.find_by!(stable_id: id)
    else
      type_de_champ.revise!
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
        procedure_revision_types_de_champ_private.find_by!(type_de_champ_id: id).update!(position: position)
      end
    else
      move_type_de_champ_hash(types_de_champ.to_a, type_de_champ, position).each do |(id, position)|
        procedure_revision_types_de_champ.find_by!(type_de_champ_id: id).update!(position: position)
      end
    end
  end

  def remove_type_de_champ(id)
    type_de_champ = find_type_de_champ_by_id(id)

    if type_de_champ.procedure_revision == self
      type_de_champ.destroy
    elsif type_de_champ.parent.present?
      find_or_clone_type_de_champ(id).destroy
    elsif type_de_champ.private?
      types_de_champ_private.delete(type_de_champ)
    else
      types_de_champ.delete(type_de_champ)
    end
  end

  def find_type_de_champ_by_id(id)
    types_de_champ.find_by(stable_id: id) ||
      types_de_champ_private.find_by(stable_id: id) ||
      TypeDeChamp.find_by!(parent_id: repetition_ids, stable_id: id)
  end

  def draft?
    procedure.draft_revision == self
  end

  def locked?
    !draft?
  end

  private

  def repetition_ids
    types_de_champ.repetition.ids + types_de_champ_private.repetition.ids
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
