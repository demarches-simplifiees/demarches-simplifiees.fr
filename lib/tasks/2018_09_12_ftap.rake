namespace :'2018_09_12_ftap' do
  task :run do
    procedure = Procedure.find(5812)
    dossiers = procedure.dossiers.all

    labels_for_text_tdc = [
      'Bref descriptif du projet',
      'Montant et nature des économies générées',
      'Contacts en cours avec les porteurs de projets'
    ]

    labels_for_text_tdc.each_with_index { |l, i| add_first_text(procedure, dossiers, l, i) }

    ditp_private_tdc_order_place = procedure.types_de_champ_private.find_by(libelle: 'Avis DITP').order_place

    labels_for_mark_before_DITP = [
      'Ambition usagers/agents',
      'Caractère stratégique et novateur',
      'Gouvernance'
    ]

    labels_for_mark_before_DITP.each_with_index { |l, i| add_mark(procedure, dossiers, l, ditp_private_tdc_order_place + i) }

    change_to_select_with_number(procedure, 'Avis DINSIC')
    change_to_select_with_number(procedure, 'Avis DB')

    change_option_for_avis_tdc(procedure)
  end

  def change_option_for_avis_tdc(procedure)
    drop_down_list = procedure.types_de_champ_private.find_by(libelle: 'Avis', type_champ: 'drop_down_list').drop_down_list
    drop_down_list.update(value: "Favorable\r\nDéfavorable\r\nFavorable avec réserves\r\nFavorable avec réserves - stratégique")
  end

  def add_first_text(procedure, dossiers, libelle, order_place)
    if procedure.types_de_champ_private.find_by(libelle: libelle).nil?

      move_down_tdc_below(procedure, order_place)

      tdc = TypesDeChamp::TextareaTypeDeChamp.create!(
        libelle: libelle,
        type_champ: 'textarea',
        procedure: procedure,
        order_place: order_place,
        private: true
      )

      procedure.types_de_champ_private << tdc

      dossiers.each do |dossier|
        dossier.champs << Champs::TextareaChamp.create!(type_de_champ: tdc, private: true)
      end
    end
  end

  def add_mark(procedure, dossiers, libelle, order_place)
    if procedure.types_de_champ_private.find_by(libelle: libelle).nil?
      move_down_tdc_below(procedure, order_place)

      tdc = TypesDeChamp::DropDownListTypeDeChamp.create!(
        libelle: libelle,
        type_champ: 'drop_down_list',
        procedure: procedure,
        order_place: order_place,
        private: true
      )

      DropDownList.create!(value: "0\r\n1\r\n2\r\n3\r\n4", type_de_champ: tdc)

      procedure.types_de_champ_private << tdc

      dossiers.each do |dossier|
        dossier.champs << Champs::DropDownListChamp.create!(type_de_champ: tdc, private: true)
      end
    end
  end

  def move_down_tdc_below(procedure, order_place)
    tdcs_to_move_down = procedure.types_de_champ_private.where('order_place >= ?', order_place)
    tdcs_to_move_down.each do |tdc|
      tdc.update(order_place: (tdc.order_place + 1))
    end
  end

  def change_to_select_with_number(procedure, libelle)
    drop_down_list = procedure.types_de_champ_private.find_by(libelle: libelle, type_champ: 'drop_down_list').drop_down_list
    drop_down_list.update(value: "0\r\n1\r\n2\r\n3\r\n4")
  end
end
