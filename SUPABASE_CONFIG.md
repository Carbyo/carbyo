# Configuration Supabase pour Carbyo iOS

Ce guide explique comment configurer l'authentification Supabase dans l'application Carbyo iOS.

## Configuration des credentials

### Option 1 : Variables d'environnement (Recommandé pour le développement)

Configurez les variables d'environnement dans Xcode :

1. Ouvrez le projet dans Xcode
2. Sélectionnez le schéma "Carbyo IOS"
3. Allez dans "Edit Scheme..." > "Run" > "Arguments"
4. Ajoutez les variables d'environnement :
   - `SUPABASE_URL` = `https://votre-projet.supabase.co`
   - `SUPABASE_ANON_KEY` = `votre-clé-anon`

### Option 2 : Info.plist (Recommandé pour la production)

Créez ou modifiez le fichier `Info.plist` :

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>SUPABASE_URL</key>
    <string>https://votre-projet.supabase.co</string>
    <key>SUPABASE_ANON_KEY</key>
    <string>votre-clé-anon</string>
</dict>
</plist>
```

**Note importante :** Si vous utilisez `GENERATE_INFOPLIST_FILE = YES` dans Xcode, vous devrez créer un fichier `Info.plist` manuel et le configurer dans les Build Settings.

### Option 3 : Configuration programmatique (Pour les tests)

Vous pouvez aussi configurer Supabase programmatiquement :

```swift
SupabaseManager.configure(
    url: "https://votre-projet.supabase.co",
    anonKey: "votre-clé-anon"
)
```

## Obtenir vos credentials Supabase

1. Connectez-vous à votre projet sur [Supabase Dashboard](https://supabase.com/dashboard)
2. Allez dans **Settings** > **API**
3. Copiez :
   - **Project URL** → `SUPABASE_URL`
   - **anon public** key → `SUPABASE_ANON_KEY`

## Structure de base de données requise

Assurez-vous que votre base de données Supabase contient les tables suivantes :

### Table `profiles`

```sql
CREATE TABLE profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id),
    email TEXT NOT NULL,
    pseudo TEXT,
    onboarding_completed BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

## Fonctionnalités d'authentification implémentées

✅ Connexion avec email/mot de passe  
✅ Inscription avec email/mot de passe  
✅ Gestion de session persistante  
✅ Chargement automatique du profil utilisateur  
✅ Déconnexion  
✅ Réinitialisation de mot de passe  
✅ Gestion d'erreurs avec messages localisés en français  

## Sécurité

⚠️ **Important :** Ne commitez JAMAIS vos clés Supabase dans Git. Utilisez :
- Des variables d'environnement pour le développement
- Un fichier `.gitignore` pour exclure les fichiers de configuration
- Des secrets gérés par votre CI/CD pour la production
