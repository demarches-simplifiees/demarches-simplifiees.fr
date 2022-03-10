# Privacy policy documentation

This document describes various privacy consideration that should be considered when deploying an instance of demarches-simplifiees.fr.
## Matomo and or Analytics service

In order to prevent Matomo to store personnal information, you should set it up with some additional configurations options.

### Exclude some query parameters from matomo

* how : [see the matomo doc](https://matomo.org/faq/how-to/faq_81/)
* what :
We recommend to ignore the following query parameters

```
fbclid
*token
/.*token/
*email*
```

* why : some pages use URL query parameters to transmit the user email address. To avoid these being logged by Matomo, they should be excluded from the logged parameters.

## Forms data requested by user :

Depending on your local regulations/laws, **beware** : you can't collect some data, others requires special infrastructure.

### Risky forms inputs in France :

* unless your instance is running on a HDS infrastructure, you can't collect any health data. This includes Social Security number, health records, etc. [Source : CNIL](https://www.cnil.fr/fr/quest-ce-ce-quune-donnee-de-sante)
* in France, a form can't ask for the race or religion. [Source : INSEE](https://www.insee.fr/fr/information/2108548)

## Data expirations :

Data retention **must not exceed 36 months**. Depending on your instance configuration, you should check that all records of the `procedures` table have the column `procedure_expires_when_termine_enabled` set to `true`. Also make sure the default value of `procedures.procedure_expires_when_termine_enabled` is true.

This flag ensures that processed file will be deleted when expired.
