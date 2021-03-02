class SerializerService
  def self.dossier(dossier)
    data = execute_query('serializeDossier', { number: dossier.id })
    data && data['dossier']
  end

  def self.avis(avis)
    data = execute_query('serializeAvis', { number: avis.dossier_id, id: avis.to_typed_id })
    data && data['dossier']['avis'].first
  end

  def self.champ(champ)
    if champ.private?
      data = execute_query('serializeAnnotation', { number: champ.dossier_id, id: champ.to_typed_id })
      data && data['dossier']['annotations'].first
    else
      data = execute_query('serializeChamp', { number: champ.dossier_id, id: champ.to_typed_id })
      data && data['dossier']['champs'].first
    end
  end

  def self.execute_query(operation_name, variables)
    result = API::V2::Schema.execute(QUERY,
      variables: variables,
      context: { internal_use: true },
      operation_name: operation_name)
    if result['errors'].present?
      raise result['errors'].first['message']
    end
    result['data']
  end

  QUERY = <<-'GRAPHQL'
    query serializeDossier($number: Int!) {
      dossier(number: $number) {
        ...DossierFragment
      }
    }

    query serializeAvis($number: Int!, $id: ID!) {
      dossier(number: $number) {
        avis(id: $id) {
          ...AvisFragment
        }
      }
    }

    query serializeChamp($number: Int!, $id: ID!) {
      dossier(number: $number) {
        champs(id: $id) {
          ...RootChampFragment
        }
      }
    }

    query serializeAnnotation($number: Int!, $id: ID!) {
      dossier(number: $number) {
        annotations(id: $id) {
          ...RootChampFragment
        }
      }
    }

    fragment DossierFragment on Dossier {
      id
      number
      archived
      state
      dateDerniereModification
      datePassageEnConstruction
      datePassageEnInstruction
      dateTraitement
      instructeurs {
        email
      }
      groupeInstructeur {
        label
      }
      champs {
        ...RootChampFragment
      }
      annotations {
        ...RootChampFragment
      }
      avis {
        ...AvisFragment
      }
      demandeur {
        ... on PersonnePhysique {
          civilite
          nom
          prenom
          dateDeNaissance
        }
        ...PersonneMoraleFragment
      }
      motivation
      motivationAttachment {
        byteSize
        checksum
        filename
        contentType
      }
    }

    fragment AvisFragment on Avis {
      id
      question
      reponse
      dateQuestion
      dateReponse
      instructeur {
        email
      }
      expert {
        email
      }
      attachment {
        byteSize
        checksum
        filename
        contentType
      }
    }

    fragment ChampFragment on Champ {
      id
      label
      stringValue
      ... on SiretChamp {
        etablissement {
          ...PersonneMoraleFragment
        }
      }
      ... on LinkedDropDownListChamp {
        primaryValue
        secondaryValue
      }
      ... on MultipleDropDownListChamp {
        values
      }
      ... on PieceJustificativeChamp {
        file {
          byteSize
          checksum
          filename
          contentType
        }
      }
      ... on AddressChamp {
        address {
          ...AddressFragment
        }
      }
    }

    fragment RootChampFragment on Champ {
      ...ChampFragment
      ... on RepetitionChamp {
        champs {
          ...ChampFragment
        }
      }
      ... on CarteChamp {
        geoAreas {
          source
          geometry {
            type
            coordinates
          }
          ... on ParcelleCadastrale {
            codeArr
            codeCom
            codeDep
            feuille
            nomCom
            numero
            section
            surfaceParcelle
            surfaceIntersection
          }
        }
      }
    }

    fragment PersonneMoraleFragment on PersonneMorale {
      siret
      siegeSocial
      naf
      libelleNaf
      address {
        ...AddressFragment
      }
      entreprise {
        siren
        capitalSocial
        numeroTvaIntracommunautaire
        formeJuridique
        formeJuridiqueCode
        nomCommercial
        raisonSociale
        siretSiegeSocial
        codeEffectifEntreprise
        dateCreation
        nom
        prenom
      }
      association {
        rna
        titre
        objet
        dateCreation
        dateDeclaration
        datePublication
      }
    }

    fragment AddressFragment on Address {
      label
      type
      streetAddress
      streetNumber
      streetName
      postalCode
      cityName
      cityCode
      departmentName
      departmentCode
      regionName
      regionCode
    }
  GRAPHQL
end
