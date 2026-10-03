# CiGuard

Gestionnaire de mots de passe Flutter, hors-ligne et chiffré, avec double vérification : **mot de passe maître puis empreinte**.

## Fonctionnalités

- **Déverrouillage en 2 étapes** : mot de passe maître, puis empreinte (désactivable). 5 échecs = coffre bloqué 15 min.
- **Coffre** : recherche, filtres (Tous, Favoris, Travail, Perso, Autre), copie en un geste.
- **Fiche identifiant** : afficher/masquer, copier, jauge de robustesse, détection de réutilisation, favoris, suppression.
- **Générateur** : 8 à 40 caractères, majuscules/minuscules/chiffres/symboles, `Random.secure()`.
- **Sécurité** : score global, mots de passe courants, faibles, réutilisés, anciens (> 1 an).
- **Protection** : verrouillage auto (30 s à 15 min et en arrière-plan), presse-papiers vidé après 30 s et marqué « sensible », captures d'écran bloquées (`FLAG_SECURE`).
- **Clé de récupération** pour rouvrir le coffre en cas d'oubli du mot de passe maître.
- **Personnalisation** : 10 styles (Graphite, Noir absolu, Minuit, Forêt, Prune, Moka, Océan, Bordeaux, Clair, Sable), 16 couleurs d'accent et un sélecteur de couleur personnalisée.

## Chiffrement

- Une clé de données aléatoire de 256 bits chiffre le coffre en **AES-256-GCM**.
- Cette clé est elle-même chiffrée deux fois : par une clé dérivée du mot de passe maître (**PBKDF2-HMAC-SHA256**, 120 000 itérations) et par une clé dérivée de la clé de récupération.
- Rien ne quitte l'appareil : pas de permission Internet, sauvegarde Android désactivée.

## Lancer le projet

```bash
flutter pub get
flutter run --release
```

Design d'origine : l'artefact CiGuard (7 écrans), police [Geist](https://github.com/vercel/geist-font) (OFL).
