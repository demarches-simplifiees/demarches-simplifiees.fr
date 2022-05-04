# == Schema Information
#
# Table name: procedure_revisions
#
#  id                           :bigint           not null, primary key
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
  belongs_to :attestation_template, inverse_of: :revisions, optional: true, dependent: :destroy
  belongs_to :dossier_submitted_message, inverse_of: :revisions, optional: true, dependent: :destroy

  has_many :dossiers, inverse_of: :revision, foreign_key: :revision_id

  has_many :revision_types_de_champ, class_name: 'ProcedureRevisionTypeDeChamp', foreign_key: :revision_id, dependent: :destroy, inverse_of: :revision
  has_many :revision_types_de_champ_public, -> { root.public_only.ordered }, class_name: 'ProcedureRevisionTypeDeChamp', foreign_key: :revision_id, dependent: :destroy, inverse_of: :revision
  has_many :revision_types_de_champ_private, -> { root.private_only.ordered }, class_name: 'ProcedureRevisionTypeDeChamp', foreign_key: :revision_id, dependent: :destroy, inverse_of: :revision
  has_many :types_de_champ, through: :revision_types_de_champ, source: :type_de_champ
  has_many :types_de_champ_public, through: :revision_types_de_champ_public, source: :type_de_champ
  has_many :types_de_champ_private, through: :revision_types_de_champ_private, source: :type_de_champ

  has_many :owned_types_de_champ, class_name: 'TypeDeChamp', foreign_key: :revision_id, dependent: :destroy, inverse_of: :revision
  has_one :draft_procedure, -> { with_discarded }, class_name: 'Procedure', foreign_key: :draft_revision_id, dependent: :nullify, inverse_of: :draft_revision
  has_one :published_procedure, -> { with_discarded }, class_name: 'Procedure', foreign_key: :published_revision_id, dependent: :nullify, inverse_of: :published_revision

  scope :ordered, -> { order(:created_at) }

  def build_champs
    types_de_champ_public.map(&:build_champ)
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
        end.create(params).migrate_parent!
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
        type_de_champ = repetition_type_de_champ.types_de_champ.find(id)
        type_de_champ.update!(order_place: position)
        type_de_champ.revision_type_de_champ&.update!(position: position)
      end
    else
      liste = type_de_champ.private? ? types_de_champ_private : types_de_champ_public

      move_type_de_champ_hash(liste.to_a, type_de_champ, position).each do |(id, position)|
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

  def different_from?(revision)
    types_de_champ != revision.types_de_champ ||
      attestation_template != revision.attestation_template
  end

  def compare(revision)
    changes = []
    changes += compare_types_de_champ(types_de_champ_public, revision.types_de_champ_public)
    changes += compare_types_de_champ(types_de_champ_private, revision.types_de_champ_private)
    changes += compare_attestation_template(attestation_template, revision.attestation_template)
    changes
  end

  def new_dossier
    Dossier.new(
      revision: self,
      champs: build_champs,
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

  private

  def compare_attestation_template(from_at, to_at)
    changes = []
    if from_at.nil? && to_at.present?
      changes << {
        model: :attestation_template,
        op: :add
      }
    elsif to_at.present?
      if from_at.title != to_at.title
        changes << {
          model: :attestation_template,
          op: :update,
          attribute: :title,
          from: from_at.title,
          to: to_at.title
        }
      end
      if from_at.body != to_at.body
        changes << {
          model: :attestation_template,
          op: :update,
          attribute: :body,
          from: from_at.body,
          to: to_at.body
        }
      end
      if from_at.footer != to_at.footer
        changes << {
          model: :attestation_template,
          op: :update,
          attribute: :footer,
          from: from_at.footer,
          to: to_at.footer
        }
      end
      if from_at.logo_checksum != to_at.logo_checksum
        changes << {
          model: :attestation_template,
          op: :update,
          attribute: :logo,
          from: from_at.logo_filename,
          to: to_at.logo_filename
        }
      end
      if from_at.signature_checksum != to_at.signature_checksum
        changes << {
          model: :attestation_template,
          op: :update,
          attribute: :signature,
          from: from_at.signature_filename,
          to: to_at.signature_filename
        }
      end
    end
    changes
  end

  def compare_types_de_champ(from_tdc, to_tdc)
    if from_tdc == to_tdc
      []
    else
      from_h = from_tdc.index_by(&:stable_id)
      to_h = to_tdc.index_by(&:stable_id)

      from_sids = from_h.keys
      to_sids = to_h.keys

      removed = (from_sids - to_sids).map do |sid|
        { model: :type_de_champ, op: :remove, label: from_h[sid].libelle, private: from_h[sid].private?, position: from_sids.index(sid), stable_id: sid }
      end

      added = (to_sids - from_sids).map do |sid|
        { model: :type_de_champ, op: :add, label: to_h[sid].libelle, private: to_h[sid].private?, position: to_sids.index(sid), stable_id: sid }
      end

      kept = from_sids.intersection(to_sids)

      moved = kept
        .map { |sid| [sid, from_sids.index(sid), to_sids.index(sid)] }
        .filter { |_, from_index, to_index| from_index != to_index }
        .map do |sid, from_index, to_index|
        { model: :type_de_champ, op: :move, label: from_h[sid].libelle, private: from_h[sid].private?, from: from_index, to: to_index, position: to_index, stable_id: sid }
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
        model: :type_de_champ,
        op: :update,
        attribute: :type_champ,
        label: from_type_de_champ.libelle,
        private: from_type_de_champ.private?,
        from: from_type_de_champ.type_champ,
        to: to_type_de_champ.type_champ,
        stable_id: from_type_de_champ.stable_id
      }
    end
    if from_type_de_champ.libelle != to_type_de_champ.libelle
      changes << {
        model: :type_de_champ,
        op: :update,
        attribute: :libelle,
        label: from_type_de_champ.libelle,
        private: from_type_de_champ.private?,
        from: from_type_de_champ.libelle,
        to: to_type_de_champ.libelle,
        stable_id: from_type_de_champ.stable_id
      }
    end
    if from_type_de_champ.description != to_type_de_champ.description
      changes << {
        model: :type_de_champ,
        op: :update,
        attribute: :description,
        label: from_type_de_champ.libelle,
        private: from_type_de_champ.private?,
        from: from_type_de_champ.description,
        to: to_type_de_champ.description,
        stable_id: from_type_de_champ.stable_id
      }
    end
    if from_type_de_champ.mandatory? != to_type_de_champ.mandatory?
      changes << {
        model: :type_de_champ,
        op: :update,
        attribute: :mandatory,
        label: from_type_de_champ.libelle,
        private: from_type_de_champ.private?,
        from: from_type_de_champ.mandatory?,
        to: to_type_de_champ.mandatory?,
        stable_id: from_type_de_champ.stable_id
      }
    end
    if to_type_de_champ.drop_down_list?
      if from_type_de_champ.drop_down_list_options != to_type_de_champ.drop_down_list_options
        changes << {
          model: :type_de_champ,
          op: :update,
          attribute: :drop_down_options,
          label: from_type_de_champ.libelle,
          private: from_type_de_champ.private?,
          from: from_type_de_champ.drop_down_list_options,
          to: to_type_de_champ.drop_down_list_options,
          stable_id: from_type_de_champ.stable_id
        }
      end
      if to_type_de_champ.linked_drop_down_list?
        if from_type_de_champ.drop_down_secondary_libelle != to_type_de_champ.drop_down_secondary_libelle
          changes << {
            model: :type_de_champ,
            op: :update,
            attribute: :drop_down_secondary_libelle,
            label: from_type_de_champ.libelle,
            private: from_type_de_champ.private?,
            from: from_type_de_champ.drop_down_secondary_libelle,
            to: to_type_de_champ.drop_down_secondary_libelle
          }
        end
        if from_type_de_champ.drop_down_secondary_description != to_type_de_champ.drop_down_secondary_description
          changes << {
            model: :type_de_champ,
            op: :update,
            attribute: :drop_down_secondary_description,
            label: from_type_de_champ.libelle,
            private: from_type_de_champ.private?,
            from: from_type_de_champ.drop_down_secondary_description,
            to: to_type_de_champ.drop_down_secondary_description
          }
        end
      end
      if from_type_de_champ.drop_down_other != to_type_de_champ.drop_down_other
        changes << {
          model: :type_de_champ,
          op: :update,
          attribute: :drop_down_other,
          label: from_type_de_champ.libelle,
          private: from_type_de_champ.private?,
          from: from_type_de_champ.drop_down_other,
          to: to_type_de_champ.drop_down_other,
          stable_id: from_type_de_champ.stable_id
        }
      end
    elsif to_type_de_champ.carte?
      if from_type_de_champ.carte_optional_layers != to_type_de_champ.carte_optional_layers
        changes << {
          model: :type_de_champ,
          op: :update,
          attribute: :carte_layers,
          label: from_type_de_champ.libelle,
          private: from_type_de_champ.private?,
          from: from_type_de_champ.carte_optional_layers,
          to: to_type_de_champ.carte_optional_layers,
          stable_id: from_type_de_champ.stable_id
        }
      end
    elsif to_type_de_champ.piece_justificative?
      if from_type_de_champ.piece_justificative_template_checksum != to_type_de_champ.piece_justificative_template_checksum
        changes << {
          model: :type_de_champ,
          op: :update,
          attribute: :piece_justificative_template,
          label: from_type_de_champ.libelle,
          private: from_type_de_champ.private?,
          from: from_type_de_champ.piece_justificative_template_filename,
          to: to_type_de_champ.piece_justificative_template_filename,
          stable_id: from_type_de_champ.stable_id
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
    types_de_champ_association = type_de_champ.private? ? :revision_types_de_champ_private : :revision_types_de_champ_public
    association = send(types_de_champ_association).find_by!(type_de_champ: type_de_champ)
    cloned_type_de_champ = type_de_champ.deep_clone(include: [:types_de_champ]) do |original, kopy|
      PiecesJustificativesService.clone_attachments(original, kopy)
    end
    cloned_type_de_champ.revision = self
    association.update!(type_de_champ: cloned_type_de_champ)
    cloned_type_de_champ.types_de_champ.each(&:migrate_parent!)
    cloned_type_de_champ
  end

  def find_type_de_champ_by_id(id)
    types_de_champ.find_by(stable_id: id) ||
      types_de_champ_in_repetition.find_by!(stable_id: id)
  end

  def types_de_champ_in_repetition
    parent_ids = types_de_champ.repetition.ids
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
