---
category: "administrateur"
subcategory: "general"
slug: "je-dois-confirmer-mon-compte-a-chaque-connexion"
locale: "fr"
keywords: "authentification, navigateur, configuration, cookies, sécurité compte"
title: "Je dois confirmer mon compte à chaque connexion"
---

# Je dois confirmer mon compte à chaque connexion

Afin de sécuriser votre compte, %{application_name} vous demande tous les mois d’authentifier votre navigateur. Il vous faut alors cliquer sur le lien de confirmation envoyé par email.

Ce processus peut parfois vous être demandé à chaque connexion. Nous avons identifié deux raisons possibles :

- Une mauvaise configuration de votre navigateur.
- Le navigateur authentifié n’est pas celui que vous utilisez.

**Le lien reçu** par email est **valide une semaine** et peut être **utilisé plusieurs fois**. Vous pouvez donc probablement le réutiliser pour authentifier votre navigateur sans attendre un nouvel email.

## Mauvaise configuration de votre navigateur

Ce problème apparaît lorsque votre navigateur est configuré de manière très sécurisée et efface les données provenant de %{application_name} à chaque fermeture.

**Solution :** Pour corriger ce problème, configurez votre navigateur pour accepter les cookies du domaine %{application_name} :

- Pour Firefox [https://support.mozilla.org/fr/kb/sites-disent-cookies-bloques-les-debloquer](https://support.mozilla.org/fr/kb/sites-disent-cookies-bloques-les-debloquer),
- Pour Chrome [https://support.google.com/accounts/answer/61416?co=GENIE.Platform%3DDesktop&hl=fr](https://support.google.com/accounts/answer/61416?co=GENIE.Platform%3DDesktop&hl=fr).

Si vous n’avez pas les droits suffisants pour modifier cette configuration, contactez votre support informatique et mettez-nous en copie : %{contact_email}

## Le navigateur authentifié n’est pas celui que vous utilisez

Il est possible que lorsque vous cliquez sur le lien de l’email, celui-ci ouvre le navigateur par défaut, souvent Internet Explorer, alors que vous utilisez un autre navigateur, comme Firefox, pour accéder à %{application_name}. Le lendemain, lorsque vous ouvrez Firefox, le navigateur n’est toujours pas authentifié et vous devez à nouveau cliquer sur le lien de connexion.

**Solution :** Copiez le lien de l’email et ouvrez-le avec le navigateur que vous utilisez habituellement pour aller sur %{application_name}.
