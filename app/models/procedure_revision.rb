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

  has_many :revision_types_de_champ, -> { root.public_only.ordered }, class_name: 'ProcedureRevisionTypeDeChamp', foreign_key: :revision_id, inverse_of: false
  has_many :revision_types_de_champ_private, -> { root.private_only.ordered }, class_name: 'ProcedureRevisionTypeDeChamp', foreign_key: :revision_id, inverse_of: false
  has_many :revision_types_de_champ_all, -> { parent_ordered }, class_name: 'ProcedureRevisionTypeDeChamp', foreign_key: :revision_id, dependent: :destroy, inverse_of: :revision
  has_many :types_de_champ, through: :revision_types_de_champ, source: :type_de_champ
  has_many :types_de_champ_private, through: :revision_types_de_champ_private, source: :type_de_champ
  has_many :types_de_champ_all, through: :revision_types_de_champ_all, source: :type_de_champ

  has_one :draft_procedure, -> { with_discarded }, class_name: 'Procedure', foreign_key: :draft_revision_id, dependent: :nullify, inverse_of: :draft_revision
  has_one :published_procedure, -> { with_discarded }, class_name: 'Procedure', foreign_key: :published_revision_id, dependent: :nullify, inverse_of: :published_revision

  scope :ordered, -> { order(:created_at) }

  def add_type_de_champ(params)
    if params[:parent_id]
      parent_id = params.delete(:parent_id)
      type_de_champ = TypeDeChamp.new(params)
      find_revision_type_de_champ_by_stable_id(parent_id)
        .revision_types_de_champ
        .create(type_de_champ: type_de_champ, revision: self)
      type_de_champ
    elsif params[:private]
      types_de_champ_private.create(params)
    else
      types_de_champ.create(params)
    end
  end

  def find_or_clone_type_de_champ(stable_id)
    revision_type_de_champ = find_revision_type_de_champ_by_stable_id(stable_id)
    type_de_champ = revision_type_de_champ.type_de_champ

    if type_de_champ.revision == self
      type_de_champ
    else
      revise_type_de_champ(revision_type_de_champ)
    end
  end

  def remove_type_de_champ(stable_id)
    revision_type_de_champ = find_revision_type_de_champ_by_stable_id(stable_id)
    type_de_champ = revision_type_de_champ.type_de_champ

    if type_de_champ.revision == self
      type_de_champ.destroy
    else
      revision_type_de_champ.destroy
    end

    updates = if revision_type_de_champ.child?
      revision_type_de_champ.revision_types_de_champ
    elsif type_de_champ.private?
      revision_types_de_champ_private
    else
      revision_types_de_champ
    end.map.with_index do |revision_type_de_champ, index|
      [revision_type_de_champ.id, { position: index }]
    end.to_h

    ProcedureRevisionTypeDeChamp.update(updates.keys, updates.values)
  end

  def move_type_de_champ(stable_id, position)
    revision_type_de_champ = find_revision_type_de_champ_by_stable_id(stable_id)

    ids = if revision_type_de_champ.child?
      revision_type_de_champ.parent.revision_types_de_champ
    elsif revision_type_de_champ.private?
      revision_types_de_champ_private
    else
      revision_types_de_champ
    end.pluck(:id)

    if ids.delete_at(ids.index(revision_type_de_champ.id))
      updates = ids.insert(position, revision_type_de_champ.id)
        .map.with_index { |id, index| [id, { position: index }] }
        .to_h

      ProcedureRevisionTypeDeChamp.update(updates.keys, updates.values)
    end
  end

  def draft?
    procedure.draft_revision == self
  end

  def locked?
    !draft?
  end

  def different_from?(revision)
    revision_types_de_champ_all != revision.revision_types_de_champ_all ||
      attestation_template != revision.attestation_template
  end

  def compare(revision)
    changes = []
    changes += compare_types_de_champ(revision_types_de_champ_all, revision.revision_types_de_champ_all)
    changes += compare_attestation_template(attestation_template, revision.attestation_template)
    changes
  end

  def new_dossier
    dossier = dossiers.build(groupe_instructeur: procedure.defaut_groupe_instructeur)
    dossier.build_default_champs
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
        .map { |sid| [sid, from_h[sid], to_h[sid]] }
        .filter { |_, from, to| from.position != to.position }
        .map do |sid, from, to|
        { model: :type_de_champ, op: :move, label: from.libelle, private: from.private?, from: from.position, to: to.position, position: to_sids.index(sid), stable_id: sid }
      end

      changed = kept
        .map { |sid| [sid, from_h[sid], to_h[sid]] }
        .flat_map do |sid, from, to|
        compare_type_de_champ(from.type_de_champ, to.type_de_champ)
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
    end
    changes
  end

  def revise_type_de_champ(revision_type_de_champ)
    cloned_type_de_champ = revision_type_de_champ.type_de_champ.deep_clone do |original, kopy|
      PiecesJustificativesService.clone_attachments(original, kopy)
    end
    revision_type_de_champ.update!(type_de_champ: cloned_type_de_champ)
    cloned_type_de_champ
  end

  def find_revision_type_de_champ_by_stable_id(stable_id)
    revision_types_de_champ_all
      .joins(:type_de_champ)
      .includes(parent: :revision_types_de_champ, type_de_champ: :revision)
      .find_by!(type_de_champ: { stable_id: stable_id })
  end
end
