module NoticeUrlHelper
  def notice_url(procedure)
    if procedure.notice.attached?
      url_for(procedure.notice)
    elsif procedure.lien_notice.present?
      procedure.lien_notice
    end
  end
end
