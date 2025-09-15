# frozen_string_literal: true

module Recovery
  class RevisionExporter
    FILE_PATH = Rails.root.join('lib', 'data', 'revision', 'export.dump')

    attr_reader :revisions, :file_path
    def initialize(revision_ids:, file_path: FILE_PATH)
      @revisions = ProcedureRevision.where(id: revision_ids)
        .preload(:revision_types_de_champ)
        .to_a
      @file_path = file_path
    end

    def dump
      @file_path.binwrite(Marshal.dump(@revisions))
    end
  end
end
