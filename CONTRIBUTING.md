# How to Contribute

> [!NOTE]
> [Lire la version française](CONTRIBUTING.fr.md)

demarches-simplifiees.fr is [free software](https://en.wikipedia.org/wiki/Free_software). You can read and modify its source code under the terms of the AGPL license.

If you would like to make improvements to demarches-simplifiees.fr, it's possible!

The best way is to **propose a modification to the main codebase**. Once accepted, your improvement will be available to all users of demarches-simplifiees.fr.

Here is the recommended process for making a change.

## 1. Discuss the improvement

The first step is usually to discuss the improvement you're proposing (if it's not a trivial change, such as fixing a typo).

To do this, [create a new issue](https://github.com/demarches-simplifiees/demarches-simplifiees.fr/issues/new) about your proposal. As much as possible, clearly state your need, your use case - and potentially how you already think about solving it.

We can then discuss to verify that the expressed need aligns with the purpose of demarches-simplifiees.fr, possibly suggest alternatives, and agree on a relevant technical implementation.

## 2. Propose code

Once the discussion is established and the technical elements are outlined, you can propose code changes. To do this, make your modifications locally and [open a Pull Request](https://github.com/demarches-simplifiees/demarches-simplifiees.fr/issues/new) with the changes you want to make.

Some tips: Be sure to clearly describe the objective and implementation of your PR when creating it. If your changes are significant, break them down into several smaller, sequential PRs, which will be easier to review. Don't forget to add automated tests to ensure your changes work properly.

Each opened PR triggers automated tests and code format verification. If your tests or formatting show errors, fix them before continuing.

A member of the development team will review your PR, possibly asking for details or changes. If no one has responded after 5 days, feel free to follow up by adding a comment to the PR.

## 3. Integration

Once your PR is approved, it will be integrated into the main codebase.

We deploy to production at least once a week (and usually more often): your changes will be available in production on [demarches-simplifiees.fr](https://www.demarches-simplifiees.fr) within a few days.

## Hosting demarches-simplifiees.fr

demarches-simplifiees.fr is **complicated to host**. Among the issues we face:

- **Data security and confidentiality**: by nature, demarches-simplifiees.fr is designed to process various types of data that may have more or less sensitive characteristics. The security of the infrastructure must be controlled and certified to guarantee data confidentiality. This involves, for example, a process of compliance with the [General Security Framework](https://www.ssi.gouv.fr/entreprise/reglementation/confiance-numerique/le-referentiel-general-de-securite-rgs/) (Référentiel Général de Sécurité), which is quite a heavy process.
  This also applies to the storage of attachments, which may also present characteristics and sensitivities whose confidentiality must be guaranteed.

  The encryption of attachments is provided by our HTTP proxy : [DS Proxy](https://github.com/demarches-simplifiees/ds_proxy), but it's optional.

- **Use of external services**: demarches-simplifiees.fr interconnects with many external services: APIs (API Entreprise, API Carto, the National Address Database, etc.) - but also services for external storage of attachments, anti-virus analysis, or sending emails. The operation of demarches-simplifiees.fr depends on the availability of these external services.
- **Updates**: the database schema changes regularly. We also code scripts to harmonize old data. Sometimes specific modifications are made to old procedures to make them comply with new business rules. We also maintain the software dependencies used - especially by reacting quickly when a security flaw is reported. These frequent production updates are essential for the proper functioning of the tool.

If you want to adapt demarches-simplifiees.fr to your needs, we recommend **proposing your modifications to the main codebase** (for example by creating an issue) **rather than hosting another instance yourself**.

If you are considering hosting an instance of demarches-simplifiees.fr yourself, unfortunately, we do not have the resources to assist you or provide technical support for your installation.

However, some organizations (the Ministry of Defense, the autonomous administration in French Polynesia, the Adullact association) have deployed separate instances. We offer to connect interested parties with these existing actors to get feedback and benefit from their experience.

## Good coding practices

Your contribution will be processed more quickly if it follows our development habits.

We work to make as many of our development practices explicit as possible, so it is strongly recommended
to familiarize yourself with our [good development practices](doc/Contributions/Pratiques-de-dev.md).

Thank you for your interest in the project!
