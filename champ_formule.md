# Spécification : Champ Formule

## Descriptif

Le champ formule permet de calculer automatiquement des valeurs **numériques ou textuelles** en fonction des champs précédents dans un formulaire. Cette fonctionnalité est particulièrement utile pour :
- Calculer des montants (TVA, totaux, remises)
- Effectuer des opérations arithmétiques (sommes, produits, pourcentages)
- Appliquer des conditions logiques simples
- **Générer du texte dynamique basé sur d'autres champs**
- **Concaténer des informations provenant de plusieurs champs**
- Valider des données saisies

### Fonctionnement

Un champ formule s'appuie sur les champs précédents pour effectuer ses calculs. Dans le cas d'une annotation privée, la formule peut référencer tous les champs usagers et toutes les annotations qui précèdent le champ formule.

La valeur calculée se met à jour automatiquement dès qu'un champ dépendant est modifié, en utilisant le système de conditions existant (modèle `Logic`).

### Types de formules supportées

- **Formules numériques** : calculs mathématiques, conditions retournant des nombres
- **Formules textuelles** : génération de texte, concaténation, conditions retournant du texte

## Gems à ajouter au projet

### Dentaku
```ruby
gem 'dentaku', '~> 3.5.4'
```

**Pourquoi Dentaku ?**
- Parser et évaluateur sécurisé pour formules mathématiques **et textuelles**
- Support des variables et fonctions personnalisées
- Gestion de la précédence des opérateurs et parenthèses
- Fonctions intégrées numériques (SUM, MIN, MAX, IF, etc.)
- **Fonctions intégrées textuelles (CONCAT, LEFT, RIGHT, MID, LEN, FIND, SUBSTITUTE, CONTAINS)**
- Évaluation sécurisée d'expressions utilisateur sans risques de sécurité
- Cache des AST pour de meilleures performances

## Étapes de développement (User Stories)

### Étape 1 : Modèle et base de données
**En tant que développeur, je veux créer le nouveau type de champ formule**

**Tâches :**
- [ ] **Ajouter `formule: 'formule'` dans `INSTANCE_TYPE_CHAMPS` du modèle `TypeDeChamp` (zone fork)**
- [ ] **Ajouter `formule: STANDARD` dans `INSTANCE_TYPE_DE_CHAMP_TO_CATEGORIE` (zone fork)**
- [ ] Créer `TypesDeChamp::FormuleTypeDeChamp` qui hérite de `TypesDeChamp::TypeDeChampBase`
- [ ] Ajouter les options `formule_expression` dans `INSTANCE_OPTIONS` et `store_accessor :options`
- [ ] Créer `Champs::FormuleChamp` qui hérite de `Champ`
- [ ] Ajouter la validation de l'expression de formule avec Dentaku
- [ ] **Implémenter la conversion automatique texte→numérique dans les calculs**
- [ ] **Retour systématiquement textuel (à confirmer dans le code)**

**Critères d'acceptation :**
- Le type de champ "formule" apparaît dans les types disponibles
- L'expression de formule est stockée dans les options du TypeDeChamp
- **Le nouveau type utilise les constantes INSTANCE_* (zone fork)**
- L'expression est validée lors de la sauvegarde
- **Les références de champs retournent systématiquement du texte**
- **Conversion automatique texte→numérique quand nécessaire**

### Étape 2 : Interface d'administration - Configuration
**En tant qu'administrateur, je veux pouvoir configurer un champ formule**

**Tâches :**
- [ ] Ajouter l'interface de configuration dans l'éditeur de champs
- [ ] Créer un champ texte pour saisir l'expression de formule
- [ ] **~~Ajouter un sélecteur pour le type de retour~~ (simplifié : retour toujours textuel)**
- [ ] Ajouter une aide contextuelle avec des exemples de formules numériques et textuelles
- [ ] Valider l'expression côté client avec un aperçu
- [ ] Lister les champs disponibles pour la formule avec leur type

**Critères d'acceptation :**
- L'administrateur peut saisir une expression de formule
- **Les champs référencés retournent toujours du texte (simplification)**
- Les champs disponibles sont affichés avec leur libellé et type
- L'expression est validée en temps réel
- Des exemples d'usage numériques et textuels sont fournis

### Étape 3 : Calcul et dépendances
**En tant que système, je veux calculer automatiquement la valeur des champs formules**

**Tâches :**
- [ ] Étendre le modèle `Logic::ChampValue` pour supporter les champs dans les formules
- [ ] Créer `Logic::FormuleChampValue` pour gérer les références aux champs dans les formules
- [ ] Implémenter le calcul de la formule dans `Champs::FormuleChamp#compute_value`
- [ ] **Implémenter la logique de conversion automatique texte→numérique pour les opérations math**
- [ ] **Retour systématiquement textuel du résultat de la formule**
- [ ] Gérer les erreurs de calcul (division par zéro, références invalides, erreurs de conversion)
- [ ] Intégrer avec le système de conditions pour détecter les changements

**Critères d'acceptation :**
- La formule est recalculée automatiquement quand un champ dépendant change
- **Toutes les références de champs sont traitées comme du texte**
- **Conversion automatique en numérique pour les opérations mathématiques**
- **Le résultat final est toujours formaté en texte**
- Les erreurs sont gérées gracieusement
- Les références aux champs sont résolues correctement

### Étape 4 : Interface utilisateur - Affichage
**En tant qu'usager, je veux voir la valeur calculée par la formule**

**Tâches :**
- [ ] Créer la vue pour `Champs::FormuleChamp` en lecture seule
- [ ] Afficher la valeur calculée (toujours textuelle)
- [ ] **Simplifier l'affichage : toujours textuel, pas de formatage spécifique**
- [ ] Montrer un indicateur de chargement pendant le calcul
- [ ] Afficher les erreurs de calcul à l'utilisateur
- [ ] Gérer l'affichage dans les différents contextes (saisie, lecture, export)

**Critères d'acceptation :**
- La valeur calculée s'affiche automatiquement
- Le champ est en lecture seule pour l'usager
- **L'affichage est toujours textuel (simplification)**
- Les erreurs sont affichées de manière compréhensible

### Étape 5 : Mise à jour dynamique
**En tant qu'usager, je veux que la formule se recalcule quand je modifie un champ**

**Tâches :**
- [ ] Étendre `ChampConditionalConcern` pour supporter les champs formules
- [ ] Implémenter la détection des dépendances de formule
- [ ] Créer le mécanisme de recalcul automatique via Stimulus/Turbo
- [ ] Optimiser les performances pour éviter les recalculs inutiles
- [ ] Gérer les dépendances circulaires

**Critères d'acceptation :**
- Le champ formule se recalcule dès qu'un champ dépendant change
- Pas de dépendances circulaires
- Performance acceptable même avec plusieurs formules

### Étape 6 : Gestion des annotations privées
**En tant qu'agent, je veux utiliser des formules dans les annotations privées**

**Tâches :**
- [ ] Adapter la logique pour que les annotations privées puissent référencer tous les champs usagers
- [ ] Modifier la résolution des dépendances pour les annotations
- [ ] Tester la compatibilité avec le workflow de traitement des dossiers
- [ ] Valider que les formules ne sont pas modifiables par l'usager

**Critères d'acceptation :**
- Les annotations privées peuvent utiliser tous les champs usagers dans leurs formules
- Les calculs sont effectués côté agent uniquement
- L'usager ne peut pas voir/modifier ces formules

### Étape 7 : Validation et tests
**En tant que développeur, je veux m'assurer de la qualité du code**

**Tâches :**
- [ ] Écrire les tests unitaires pour `TypesDeChamp::FormuleTypeDeChamp`
- [ ] Écrire les tests unitaires pour `Champs::FormuleChamp`
- [ ] Écrire les tests d'intégration pour les calculs numériques et textuels
- [ ] Tester les cas d'erreur et les limites
- [ ] **Tester les fonctions de manipulation de chaînes**
- [ ] Ajouter les tests de performance

**Critères d'acceptation :**
- Couverture de tests > 90%
- Tous les cas d'usage numériques et textuels sont testés
- Les performances sont acceptables

### Étape 8 : Documentation et formation
**En tant qu'utilisateur, je veux comprendre comment utiliser les formules**

**Tâches :**
- [ ] Rédiger la documentation utilisateur pour les formules
- [ ] **Créer des exemples d'usage courants (numériques et textuels)**
- [ ] Documenter les fonctions disponibles (math + chaînes)
- [ ] Ajouter des tooltips et aide contextuelle
- [ ] Créer un guide de migration si nécessaire

**Critères d'acceptation :**
- Documentation complète et claire
- Exemples d'usage numériques et textuels disponibles
- Aide contextuelle dans l'interface

## Questions et points d'attention

### Questions techniques :

1. **Syntaxe des formules** : Utiliserons-nous la syntaxe Dentaku standard
   - ✅ **Validé** : Syntaxe Dentaku standard pour la simplicité

2. **Référencement des champs** : Comment référencer les autres champs dans les formules ?
   - ✅ **Validé** : Syntaxe moustache `{Libellé du champ}`

3. **Gestion des types** : Comment gérer les différents types de champs ?
   - ✅ **Validé** : **Toutes les références de champs retournent du texte**
   - ✅ **Validé** : **Conversion automatique texte→numérique pour les calculs**
   - ✅ **Validé** : **Résultat toujours textuel (simplification)**

4. **Zone de code (Fork)** : Où placer le nouveau type de champ ?
   - ✅ **Validé** : **Utiliser les constantes INSTANCE_* pour le fork**

5. **Performance** : Comment optimiser les recalculs pour de gros formulaires ?
   - Cache des expressions parsées
   - Calcul paresseux (lazy evaluation)
   - Éviter les recalculs en cascade

6. **Sécurité** : Quelles sont les fonctions autorisées dans les formules ?
   - Fonctions mathématiques standard
   - **Fonctions de manipulation de chaînes Dentaku**
   - Pas d'accès aux fonctions système

### Cas d'usage exemples :

#### Formules numériques :
```
Montant TTC = {Montant HT} * (1 + {Taux TVA} / 100)
Remise = IF({Type client} = "VIP", {Montant} * 0.1, 0)
Total = SUM({Produit 1}, {Produit 2}, {Produit 3})
Age = ROUNDDOWN((TODAY() - {Date de naissance}) / 365.25)
```

#### Formules textuelles :
```
Civilité complète = IF({Civilité} = "M", "Monsieur", "Madame")
Nom complet = CONCAT({Prénom}, " ", {Nom})
Message = IF({Age} >= 18, "Vous êtes majeur", "Vous êtes mineur")
Adresse complète = CONCAT({Adresse}, ", ", {Code postal}, " ", {Ville})
Statut = IF({Type client} = "VIP", "Client privilégié", "Client standard")
Résumé = CONCAT("Commande de ", {Nom complet}, " pour ", {Montant TTC}, " €")
```

#### Formules mixtes (conditions sur nombres, retour texte) :
```
Tranche d'âge = IF({Age} < 18, "Mineur", IF({Age} < 65, "Adulte", "Senior"))
Catégorie montant = IF({Montant} < 100, "Petit achat", IF({Montant} < 1000, "Achat moyen", "Gros achat"))
```

### Fonctions Dentaku disponibles :

#### Fonctions mathématiques :
- Arithmétiques : `+`, `-`, `*`, `/`, `%`
- Comparaisons : `=`, `!=`, `<`, `>`, `<=`, `>=`
- Logiques : `AND`, `OR`, `NOT`
- Conditions : `IF(condition, si_vrai, si_faux)`
- Agrégation : `SUM()`, `MIN()`, `MAX()`, `AVG()`
- Math : `ROUND()`, `ROUNDUP()`, `ROUNDDOWN()`, `ABS()`, `SQRT()`

#### Fonctions textuelles :
- Concaténation : `CONCAT()`
- Extraction : `LEFT()`, `RIGHT()`, `MID()`
- Informations : `LEN()`, `FIND()`, `CONTAINS()`
- Transformation : `SUBSTITUTE()`

### Contraintes spécifiques au fork :

1. **Utilisation des constantes INSTANCE_*** :
   - `INSTANCE_TYPE_CHAMPS` : Ajout du type `formule: 'formule'`
   - `INSTANCE_TYPE_DE_CHAMP_TO_CATEGORIE` : Classification `formule: STANDARD`
   - `INSTANCE_OPTIONS` : Ajout de `formule_expression`

2. **Gestion des types simplifiée** :
   - **Toutes les références de champs retournent systématiquement du texte**
   - **Conversion automatique texte→numérique lors des opérations mathématiques**
   - **Résultat final toujours textuel (pas de type de retour à choisir)**

3. **À confirmer dans le code** :
   - Vérifier que les références aux champs donnent bien du texte
   - Valider l'approche du retour systématiquement textuel
   - Optimiser la conversion automatique des types

### Limitations initiales :

- Expressions limitées à 1000 caractères
- Limitation à 10 niveaux de dépendances
- **Résultat toujours textuel (simplification)**
- Pas de fonctions de date avancées (dans un premier temps)