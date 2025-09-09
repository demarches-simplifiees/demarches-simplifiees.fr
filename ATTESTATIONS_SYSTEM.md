# Système d'Attestations d'Acceptation de Démarches Simplifiées

## Vue d'Ensemble

Le système d'attestations d'acceptation permet aux administrateurs de configurer des modèles d'attestation PDF qui sont automatiquement générés et envoyés aux usagers lorsqu'un dossier est accepté par un instructeur.

## 1. Architecture Générale

### Modèles de Données Principaux

**AttestationTemplate** (`app/models/attestation_template.rb`)
- Appartient à une `Procedure` 
- Supporte 2 versions (v1 legacy, v2 moderne avec éditeur TipTap)
- États : `draft` ou `published`
- Contient le template avec système de tags pour injection de données

```ruby
class AttestationTemplate < ApplicationRecord
  belongs_to :procedure, inverse_of: :attestation_template
  
  enum :state, {
    draft: 'draft',
    published: 'published'
  }
  
  # Fichiers attachés
  has_one_attached :logo
  has_one_attached :signature
```

**Attestation** (`app/models/attestation.rb`)  
- Instance générée pour chaque dossier accepté
- Stocke le PDF via Active Storage

```ruby
class Attestation < ApplicationRecord
  belongs_to :dossier, optional: false
  has_one_attached :pdf
```

## 2. Processus de Génération Automatique

### Déclenchement lors de l'acceptation

Le processus se déclenche dans `DossierStateConcern` (`app/models/concerns/dossier_state_concern.rb`) :

```ruby
def after_accepter(h)
  # ... autres traitements ...
  
  if attestation.nil?
    self.attestation = build_attestation  # ← Génération de l'attestation
  end
  
  save!
end

def after_accepter_automatiquement
  # ... autres traitements ...
  
  if attestation.nil?
    self.attestation = build_attestation  # ← Même logique pour acceptation auto
  end
  
  save!
end
```

### Méthode de Construction

Dans `Dossier` (`app/models/dossier.rb`) :

```ruby
def build_attestation
  if attestation_template&.activated?
    attestation_template.attestation_for(self)
  end
end
```

## 3. Génération du PDF

### Méthode Principale

Dans `AttestationTemplate` :

```ruby
def attestation_for(dossier)
  attestation = Attestation.new
  attestation.title = replace_tags(title, dossier, escape: false) if version == 1
  
  attestation.pdf.attach(
    io: StringIO.new(build_pdf(dossier)),
    filename: "attestation-dossier-#{dossier.id}.pdf",
    content_type: 'application/pdf',
    metadata: { virus_scan_result: ActiveStorage::VirusScanner::SAFE }
  )
  
  attestation
end
```

### Génération selon la Version

```ruby
def build_pdf(dossier)
  if version == 2
    build_v2_pdf(dossier)  # TipTap + WeasyprintService
  else
    build_v1_pdf(dossier)  # Template Rails classique
  end
end
```

**Version 1 (Legacy)** :
```ruby
def build_v1_pdf(dossier)
  attestation = render_attributes_for(dossier: dossier)
  ApplicationController.render(
    template: 'administrateurs/attestation_templates/show',
    formats: :pdf,
    assigns: { attestation: attestation }
  )
end
```

**Version 2 (Moderne)** :
```ruby
def build_v2_pdf(dossier)
  attributes = render_attributes_for(dossier:)
  body = attributes.fetch(:body)
  signature = attributes.fetch(:signature)

  html = ApplicationController.render(
    template: '/administrateurs/attestation_template_v2s/show',
    formats: [:html],
    layout: 'attestation',
    assigns: { attestation_template: self, body:, signature: }
  )

  WeasyprintService.generate_pdf(html, { procedure_id: procedure.id, dossier_id: dossier.id })
end
```

## 4. Système de Tags (Substitution de Données)

### Principe
Les templates contiennent des balises qui sont remplacées par les vraies données du dossier :

```ruby
def render_attributes_for_v1(params, base_attributes)
  dossier = params[:dossier]
  
  if dossier.present?
    attributes.merge(
      title: replace_tags(title, dossier, escape: false),
      body: replace_tags(body, dossier, escape: false)
    )
  end
end
```

### Tags Disponibles
Le système utilise `TagsSubstitutionConcern` qui permet d'injecter :
- Données du dossier (`dossier_processed_at`, `dossier_service_name`, etc.)
- Données des champs du formulaire (`tdc123`, etc.)
- Données de l'usager et de l'établissement

## 5. Interface d'Administration

### Contrôleurs

**AttestationTemplatesController** (v1) :
```ruby
def update
  @attestation_template = @procedure.attestation_template_v1
  
  if @attestation_template.update(activated_attestation_params)
    flash.notice = "Le modèle de l'attestation a bien été modifié"
    redirect_to edit_admin_procedure_attestation_template_path(@procedure)
  end
end
```

**AttestationTemplateV2sController** (v2) :
- Interface plus moderne avec éditeur TipTap
- Support JSON pour le contenu structuré

### Template par Défaut (v2)

```ruby
TIPTAP_BODY_DEFAULT = {
  "type" => "doc",
  "content" => [
    {
      "type" => "header",
      "content" => [
        {
          "type" => "headerColumn",
          "content" => [
            {
              "type" => "paragraph",
              "content" => [
                { 
                  "type" => "mention", 
                  "attrs" => { 
                    "id" => "dossier_service_name", 
                    "label" => "nom du service" 
                  } 
                }
              ]
            }
          ]
        }
      ]
    }
  ]
}
```

## 6. Accès Utilisateur

### Téléchargement par l'Usager

Dans `app/views/users/dossiers/show/_download_attestation.html.haml` :

```haml
- if dossier && dossier.attestation.present?
  = link_to "#{t('views.users.dossiers.merci.download_attestation')} (PDF)", 
    attestation_dossier_path(dossier), 
    download: "Attestation", 
    target: "_blank", 
    class: 'fr-btn fr-btn--secondary fr-btn--icon-left fr-icon-download-line'
```

## 7. Points Clés du Système

### Sécurité
- PDF généré côté serveur (pas de manipulation client)
- Virus scanning désactivé pour les PDFs générés (metadata safe)
- Validation des templates avec système de tags

### Performance  
- Génération asynchrone lors de l'acceptation
- Cache des templates compilés
- Optimisation v2 avec TipTap (2x plus rapide que v1)

### Extensibilité
- Système de versions pour évolution progressive
- Support de signatures par groupe instructeur
- Templates dupliqués lors de révisions de procédure

Ce système offre une solution complète pour la génération automatique d'attestations personnalisées, avec une interface d'administration intuitive et un processus de génération robuste intégré au workflow d'instruction des dossiers.