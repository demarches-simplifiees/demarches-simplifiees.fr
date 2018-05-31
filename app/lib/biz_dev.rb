module BizDev
  BIZ_DEV_MAPPING = {
    8 =>
      {
        full_name: "Camille Garrigue",
        pipedrive_id: 3189424
      },
    9 =>
      {
        full_name: "Philippe Vrignaud",
        pipedrive_id: 2753338
      },
    10 =>
      {
        full_name: "Benjamin Doberset",
        pipedrive_id: 4223834
      },
    11 =>
      {
        full_name: "Rédouane Bouchane",
        pipedrive_id: 4438645
      }
  }

  BIZ_DEV_IDS = BIZ_DEV_MAPPING.keys

  def full_name(administration_id)
    id = ensure_proper_administration_id(administration_id)

    BIZ_DEV_MAPPING[id][:full_name]
  end

  def pipedrive_id(administration_id)
    id = ensure_proper_administration_id(administration_id)

    BIZ_DEV_MAPPING[id][:pipedrive_id]
  end

  private

  def ensure_proper_administration_id(administration_id)
    if administration_id.in?(BIZ_DEV_IDS)
      administration_id
    else
      BIZ_DEV_IDS[administration_id % BIZ_DEV_IDS.length]
    end
  end
end
