class API::V2::StoredQuery
  def self.get(query_id, fallback: nil)
    case query_id
    when 'ds-query-v2'
      QUERY_V2
    when 'ds-mutation-v2'
      MUTATION_V2
    else
      if fallback.nil?
        raise GraphQL::ExecutionError.new("No query with id \"#{query_id}\"")
      else
        fallback
      end
    end
  end

  QUERY_V2 = <<-'GRAPHQL'
  query getDemarche(
    $demarcheNumber: Int!
    $state: DossierState
    $order: Order
    $first: Int
    $after: String
    $archived: Boolean
    $revision: ID
    $createdSince: ISO8601DateTime
    $updatedSince: ISO8601DateTime
    $deletedOrder: Order
    $deletedFirst: Int
    $deletedAfter: String
    $deletedSince: ISO8601DateTime
    $includeGroupeInstructeurs: Boolean = false
    $includeDossiers: Boolean = false
    $includeDeletedDossiers: Boolean = false
    $includeRevision: Boolean = false
    $includeService: Boolean = false
    $includeChamps: Boolean = true
    $includeAnotations: Boolean = true
    $includeTraitements: Boolean = true
    $includeInstructeurs: Boolean = true
    $includeAvis: Boolean = false
    $includeMessages: Boolean = false
    $includeGeometry: Boolean = false
  ) {
    demarche(number: $demarcheNumber) {
      id
      number
      title
      state
      declarative
      dateCreation
      dateFermeture
      publishedRevision @include(if: $includeRevision) {
        ...RevisionFragment
      }
      groupeInstructeurs @include(if: $includeGroupeInstructeurs) {
        ...GroupeInstructeurFragment
      }
      service @include(if: $includeService) {
        ...ServiceFragment
      }
      dossiers(
        state: $state
        order: $order
        first: $first
        after: $after
        archived: $archived
        createdSince: $createdSince
        updatedSince: $updatedSince
        revision: $revision
      ) @include(if: $includeDossiers) {
        pageInfo {
          ...PageInfoFragment
        }
        nodes {
          ...DossierFragment
        }
      }
      deletedDossiers(
        order: $deletedOrder
        first: $deletedFirst
        after: $deletedAfter
        deletedSince: $deletedSince
      ) @include(if: $includeDeletedDossiers) {
        pageInfo {
          ...PageInfoFragment
        }
        nodes {
          ...DeletedDossierFragment
        }
      }
    }
  }

  query getGroupeInstructeur(
    $groupeInstructeurNumber: Int!
    $state: DossierState
    $order: Order
    $first: Int
    $after: String
    $archived: Boolean
    $revision: ID
    $createdSince: ISO8601DateTime
    $updatedSince: ISO8601DateTime
    $deletedOrder: Order
    $deletedFirst: Int
    $deletedAfter: String
    $deletedSince: ISO8601DateTime
    $includeDossiers: Boolean = false
    $includeDeletedDossiers: Boolean = false
    $includeChamps: Boolean = true
    $includeAnotations: Boolean = true
    $includeTraitements: Boolean = true
    $includeInstructeurs: Boolean = true
    $includeAvis: Boolean = false
    $includeMessages: Boolean = false
    $includeGeometry: Boolean = false
  ) {
    groupeInstructeur(number: $groupeInstructeurNumber) {
      id
      number
      label
      instructeurs @include(if: $includeInstructeurs) {
        id
        email
      }
      dossiers(
        state: $state
        order: $order
        first: $first
        after: $after
        archived: $archived
        createdSince: $createdSince
        updatedSince: $updatedSince
        revision: $revision
      ) @include(if: $includeDossiers) {
        pageInfo {
          ...PageInfoFragment
        }
        nodes {
          ...DossierFragment
        }
      }
      deletedDossiers(
        order: $deletedOrder
        first: $deletedFirst
        after: $deletedAfter
        deletedSince: $deletedSince
      ) @include(if: $includeDeletedDossiers) {
        pageInfo {
          ...PageInfoFragment
        }
        nodes {
          ...DeletedDossierFragment
        }
      }
    }
  }

  query getDossier(
    $dossierNumber: Int!
    $includeRevision: Boolean = false
    $includeService: Boolean = false
    $includeChamps: Boolean = true
    $includeAnotations: Boolean = true
    $includeTraitements: Boolean = true
    $includeInstructeurs: Boolean = true
    $includeAvis: Boolean = false
    $includeMessages: Boolean = false
    $includeGeometry: Boolean = false
  ) {
    dossier(number: $dossierNumber) {
      ...DossierFragment
      demarche {
        ...DemarcheDescriptorFragment
      }
    }
  }

  query getDemarcheDescriptor(
    $demarche: FindDemarcheInput!
    $includeRevision: Boolean = false
    $includeService: Boolean = false
  ) {
    demarcheDescriptor(demarche: $demarche) {
      ...DemarcheDescriptorFragment
    }
  }

  fragment ServiceFragment on Service {
    nom
    siret
    organisme
    typeOrganisme
  }

  fragment GroupeInstructeurFragment on GroupeInstructeur {
    id
    number
    label
    instructeurs @include(if: $includeInstructeurs) {
      id
      email
    }
  }

  fragment DossierFragment on Dossier {
    id
    number
    archived
    state
    dateDerniereModification
    dateDepot
    datePassageEnConstruction
    datePassageEnInstruction
    dateTraitement
    dateExpiration
    dateSuppressionParUsager
    motivation
    motivationAttachment {
      ...FileFragment
    }
    attestation {
      ...FileFragment
    }
    pdf {
      url
    }
    usager {
      email
    }
    groupeInstructeur {
      ...GroupeInstructeurFragment
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
    demarche {
      revision {
        id
      }
    }
    instructeurs @include(if: $includeInstructeurs) {
      id
      email
    }
    traitements @include(if: $includeTraitements) {
      state
      emailAgentTraitant
      dateTraitement
      motivation
    }
    champs @include(if: $includeChamps) {
      ...ChampFragment
      ...RootChampFragment
    }
    annotations @include(if: $includeAnotations) {
      ...ChampFragment
      ...RootChampFragment
    }
    avis @include(if: $includeAvis) {
      ...AvisFragment
    }
    messages @include(if: $includeMessages) {
      ...MessageFragment
    }
  }

  fragment DemarcheDescriptorFragment on DemarcheDescriptor {
    id
    number
    title
    description
    state
    declarative
    dateCreation
    datePublication
    dateDerniereModification
    dateDepublication
    dateFermeture
    service @include(if: $includeService) {
      ...ServiceFragment
    }
    revision @include(if: $includeRevision) {
      ...RevisionFragment
    }
  }

  fragment DeletedDossierFragment on DeletedDossier {
    id
    number
    dateSupression
    state
    reason
  }

  fragment RevisionFragment on Revision {
    id
    datePublication
    champDescriptors {
      ...ChampDescriptorFragment
      champDescriptors {
        ...ChampDescriptorFragment
      }
    }
    annotationDescriptors {
      ...ChampDescriptorFragment
      champDescriptors {
        ...ChampDescriptorFragment
      }
    }
  }

  fragment ChampDescriptorFragment on ChampDescriptor {
    id
    type
    label
    description
    required
    options
  }

  fragment AvisFragment on Avis {
    id
    question
    reponse
    dateQuestion
    dateReponse
    claimant {
      email
    }
    expert {
      email
    }
    attachments {
      ...FileFragment
    }
  }

  fragment MessageFragment on Message {
    id
    email
    body
    createdAt
    attachments {
      ...FileFragment
    }
  }

  fragment GeoAreaFragment on GeoArea {
    id
    source
    description
    geometry @include(if: $includeGeometry) {
      type
      coordinates
    }
    ... on ParcelleCadastrale {
      commune
      numero
      section
      prefixe
      surface
    }
  }

  fragment RootChampFragment on Champ {
    ... on RepetitionChamp {
      rows {
        champs {
          ...ChampFragment
        }
      }
    }
    ... on CarteChamp {
      geoAreas {
        ...GeoAreaFragment
      }
    }
    ... on DossierLinkChamp {
      dossier {
        id
        number
        state
      }
    }
  }

  fragment ChampFragment on Champ {
    id
    __typename
    label
    stringValue
    ... on DateChamp {
      date
    }
    ... on DatetimeChamp {
      datetime
    }
    ... on CheckboxChamp {
      checked: value
    }
    ... on DecimalNumberChamp {
      decimalNumber: value
    }
    ... on IntegerNumberChamp {
      integerNumber: value
    }
    ... on CiviliteChamp {
      civilite: value
    }
    ... on LinkedDropDownListChamp {
      primaryValue
      secondaryValue
    }
    ... on MultipleDropDownListChamp {
      values
    }
    ... on PieceJustificativeChamp {
      files {
        ...FileFragment
      }
    }
    ... on AddressChamp {
      address {
        ...AddressFragment
      }
    }
    ... on CommuneChamp {
      commune {
        name
        code
      }
      departement {
        name
        code
      }
    }
    ... on DepartementChamp {
      departement {
        name
        code
      }
    }
    ... on RegionChamp {
      region {
        name
        code
      }
    }
    ... on PaysChamp {
      pays {
        name
        code
      }
    }
    ... on SiretChamp {
      etablissement {
        ...PersonneMoraleFragment
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
      attestationFiscaleAttachment {
        ...FileFragment
      }
      attestationSocialeAttachment {
        ...FileFragment
      }
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

  fragment FileFragment on File {
    filename
    contentType
    checksum
    byteSize: byteSizeBigInt
    url
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

  fragment PageInfoFragment on PageInfo {
    hasPreviousPage
    hasNextPage
    endCursor
  }
  GRAPHQL

  MUTATION_V2 = <<-'GRAPHQL'
  mutation dossierArchiver($input: DossierArchiverInput!) {
    dossierArchiver(input: $input) {
      dossier {
        id
        archived
      }
      errors {
        message
      }
    }
  }

  mutation dossierPasserEnInstruction($input: DossierPasserEnInstructionInput!) {
    dossierPasserEnInstruction(input: $input) {
      dossier {
        id
        state
      }
      errors {
        message
      }
    }
  }

  mutation dossierRepasserEnConstruction(
    $input: DossierRepasserEnConstructionInput!
  ) {
    dossierRepasserEnConstruction(input: $input) {
      dossier {
        id
        state
      }
      errors {
        message
      }
    }
  }

  mutation dossierAccepter($input: DossierAccepterInput!) {
    dossierAccepter(input: $input) {
      dossier {
        id
        state
        attestation {
          url
        }
      }
      errors {
        message
      }
    }
  }

  mutation dossierRefuser($input: DossierRefuserInput!) {
    dossierRefuser(input: $input) {
      dossier {
        id
        state
      }
      errors {
        message
      }
    }
  }

  mutation dossierClasserSansSuite($input: DossierClasserSansSuiteInput!) {
    dossierClasserSansSuite(input: $input) {
      dossier {
        id
        state
      }
      errors {
        message
      }
    }
  }

  mutation dossierRepasserEnInstruction(
    $input: DossierRepasserEnInstructionInput!
  ) {
    dossierRepasserEnInstruction(input: $input) {
      dossier {
        id
        state
      }
      errors {
        message
      }
    }
  }

  mutation dossierEnvoyerMessage($input: DossierEnvoyerMessageInput!) {
    dossierEnvoyerMessage(input: $input) {
      message {
        id
        createdAt
      }
      errors {
        message
      }
    }
  }

  mutation dossierModifierAnnotationText(
    $input: DossierModifierAnnotationTextInput!
  ) {
    dossierModifierAnnotationText(input: $input) {
      annotation {
        id
        value: stringValue
      }
      errors {
        message
      }
    }
  }

  mutation dossierModifierAnnotationCheckbox(
    $input: DossierModifierAnnotationCheckboxInput!
  ) {
    dossierModifierAnnotationCheckbox(input: $input) {
      annotation {
        id
        ... on CheckboxChamp {
          value
        }
      }
      errors {
        message
      }
    }
  }

  mutation dossierModifierAnnotationDate(
    $input: DossierModifierAnnotationDateInput!
  ) {
    dossierModifierAnnotationDate(input: $input) {
      annotation {
        id
        ... on DateChamp {
          value: date
        }
      }
      errors {
        message
      }
    }
  }

  mutation dossierModifierAnnotationDateTime(
    $input: DossierModifierAnnotationDatetimeInput!
  ) {
    dossierModifierAnnotationDatetime(input: $input) {
      annotation {
        id
        ... on DatetimeChamp {
          value: datetime
        }
      }
      errors {
        message
      }
    }
  }

  mutation dossierModifierAnnotationIntegerNumber(
    $input: DossierModifierAnnotationIntegerNumberInput!
  ) {
    dossierModifierAnnotationIntegerNumber(input: $input) {
      annotation {
        id
        ... on IntegerNumberChamp {
          value
        }
      }
      errors {
        message
      }
    }
  }

  mutation dossierModifierAnnotationAjouterLigne(
    $input: DossierModifierAnnotationAjouterLigneInput!
  ) {
    dossierModifierAnnotationAjouterLigne(input: $input) {
      annotation {
        id
      }
      errors {
        message
      }
    }
  }

  mutation createDirectUpload($input: CreateDirectUploadInput!) {
    createDirectUpload(input: $input) {
      directUpload {
        signedBlobId
        headers
        url
      }
    }
  }

  mutation groupeInstructeurModifier($input: GroupeInstructeurModifierInput!) {
    groupeInstructeurModifier(input: $input) {
      groupeInstructeur {
        id
      }
      errors {
        message
      }
    }
  }

  mutation groupeInstructeurCreer($input: GroupeInstructeurCreerInput!, $includeInstructeurs: Boolean = false) {
    groupeInstructeurCreer(input: $input) {
      groupeInstructeur {
        id
        instructeurs @include(if: $includeInstructeurs) {
          id
          email
        }
      }
      errors {
        message
      }
      warnings {
        message
      }
    }
  }

  mutation groupeInstructeurAjouterInstructeurs($input: GroupeInstructeurAjouterInstructeursInput!, $includeInstructeurs: Boolean = false) {
    groupeInstructeurAjouterInstructeurs(input: $input) {
      groupeInstructeur {
        id
        instructeurs @include(if: $includeInstructeurs) {
          id
          email
        }
      }
      errors {
        message
      }
      warnings {
        message
      }
    }
  }

  mutation groupeInstructeurSupprimerInstructeurs($input: GroupeInstructeurSupprimerInstructeursInput!, $includeInstructeurs: Boolean = false) {
    groupeInstructeurSupprimerInstructeurs(input: $input) {
      groupeInstructeur {
        id
        instructeurs @include(if: $includeInstructeurs) {
          id
          email
        }
      }
      errors {
        message
      }
    }
  }

  mutation demarcheCloner($input: DemarcheClonerInput!) {
    demarcheCloner(input: $input) {
      demarche {
        id
        number
      }
      errors {
        message
      }
    }
  }
  GRAPHQL
end
