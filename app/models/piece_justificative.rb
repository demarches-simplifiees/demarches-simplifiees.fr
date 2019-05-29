class PieceJustificative < ApplicationRecord
  belongs_to :dossier, inverse_of: :pieces_justificatives, touch: true
  belongs_to :type_de_piece_justificative
  has_one :commentaire

  belongs_to :user

  delegate :api_entreprise, :libelle, :order_place, to: :type_de_piece_justificative

  alias_attribute :type, :type_de_piece_justificative_id

  mount_uploader :content, PieceJustificativeUploader
  validates :content, :file_size => { :maximum => 20.megabytes }
  validates :content, presence: true, allow_blank: false, allow_nil: false

  scope :updated_since?, -> (date) { where('pieces_justificatives.updated_at > ?', date) }

  def empty?
    content.blank?
  end

  def libelle
    if type_de_piece_justificative.nil?
      return content.to_s
    else
      type_de_piece_justificative.libelle
    end
  end

  def content_url
    if content.url.present?
      if Flipflop.remote_storage?
        (RemoteDownloader.new content.filename).url
      else
        (LocalDownloader.new content.path,
          (type_de_piece_justificative.nil? ? content.original_filename : type_de_piece_justificative.libelle)).url
      end
    end
  end

  def self.accept_format
    " application/pdf,
      application/msword,
      application/vnd.openxmlformats-officedocument.wordprocessingml.document,
      application/vnd.ms-excel,
      application/vnd.openxmlformats-officedocument.spreadsheetml.sheet,
      application/vnd.ms-powerpoint,
      application/vnd.openxmlformats-officedocument.presentationml.presentation,
      application/vnd.oasis.opendocument.text,
      application/vnd.oasis.opendocument.presentation,
      application/vnd.oasis.opendocument.spreadsheet,
      image/png,
      image/jpeg
    "
  end
end
