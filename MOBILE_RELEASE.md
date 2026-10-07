# Publication mobile — état du 7 octobre 2026

La présence des applications dans Firebase ne constitue pas une publication dans Google Play ou l’App Store.

## Android

- Identifiant : `com.sakinaacademy.app`, cohérent avec la configuration Firebase.
- Signature release configurée avec la clé locale existante. Conserver une sauvegarde privée de la clé et de ses paramètres.
- Le [Android App Bundle](build/app/outputs/bundle/release/app-release.aab) a été régénéré (190 948 033 octets). La vérification `jarsigner -verify` renvoie `jar verified` et un code de sortie 0, avec des avertissements de certificat autosigné, d’absence d’horodatage et de lecture séquentielle du manifeste. L’acceptation par Google Play reste à vérifier, ainsi que la taille de téléchargement calculée par la console.
- Se connecter à Google Play Console, sélectionner ou créer l’application, puis téléverser le bundle dans une piste de test.
- Ajouter dans Firebase les empreintes du certificat **Play App Signing**, qui peuvent différer de celles de la clé de téléversement.
- Valider sur un téléphone installé depuis Google Play : connexion e-mail, SMS, lecture audio/vidéo, cours et questionnaires.

## iOS

- Identifiant : `com.sakinaacademy.app`, cohérent avec Firebase.
- Le [fichier Firebase](ios/Runner/GoogleService-Info.plist) a été ajouté aux ressources du [projet Xcode](ios/Runner.xcodeproj/project.pbxproj).
- Aucune équipe Apple de signature n’est renseignée dans le projet. Aucune compilation iOS n’a été validée sur ce poste Windows.
- Sur un Mac avec une version de Xcode acceptée par App Store Connect : installer les dépendances Flutter, ouvrir `ios/Runner.xcworkspace`, sélectionner l’équipe Apple Developer et configurer la signature, puis lancer `flutter build ipa --release`.
- Pour la connexion SMS, terminer la configuration APNs et du schéma URL de retour reCAPTCHA dans Xcode/Firebase ; ces éléments ne sont pas encore configurés dans le projet inspecté. Tester sur un iPhone réel.
- Téléverser l’IPA signé dans App Store Connect et valider avec TestFlight avant la soumission.

## Points restant à traiter avant une soumission publique

- Confirmer les accès Google Play Console et Apple Developer/App Store Connect.
- Préparer les captures, la description, le contact d’assistance et la politique de confidentialité ; remplir les déclarations de données à partir du fonctionnement réel de l’application.
- L’application permet de créer un compte, mais aucune fonction de suppression du compte utilisateur n’a été trouvée lors de cette inspection. Préparer ce parcours avant la soumission aux stores.
- Vérifier le stockage Firebase et ses règles en production, puis les parcours complets sur les deux plateformes.
- Vérifier dans les consoles les exigences SDK, les tests requis et les éventuels refus ; incrémenter le numéro de build si une version portant déjà ce numéro a été téléversée.

## Documentation officielle

- [Publication Android avec Flutter](https://docs.flutter.dev/deployment/android)
- [Publication iOS avec Flutter](https://docs.flutter.dev/deployment/ios)
- [Authentification téléphonique Firebase sur iOS](https://firebase.google.com/docs/auth/ios/phone-auth)
- [Tests Google Play pour les nouveaux comptes personnels](https://support.google.com/googleplay/android-developer/answer/14151465)
