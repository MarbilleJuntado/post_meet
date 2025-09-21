# 🚀 Heroku Deployment Guide for PostMeet

This guide will walk you through deploying PostMeet to Heroku step by step.

## 📋 Prerequisites

- Heroku CLI installed
- Git repository set up
- All third-party API accounts configured
- Environment variables ready

## 🔧 Step 1: Install Heroku CLI

### macOS
```bash
brew install heroku/brew/heroku
```

### Ubuntu/Debian
```bash
curl https://cli-assets.heroku.com/install.sh | sh
```

### Windows
Download from [Heroku CLI](https://devcenter.heroku.com/articles/heroku-cli)

## 🔐 Step 2: Login to Heroku

```bash
heroku login
```

## 🏗️ Step 3: Create Heroku App

```bash
# Create app (replace 'your-app-name' with your desired name)
heroku create your-app-name

# Or create with specific region
heroku create your-app-name --region us
```

## 🗄️ Step 4: Add PostgreSQL Database

```bash
# Add PostgreSQL addon (free tier)
heroku addons:create heroku-postgresql:mini

# Check database info
heroku pg:info
```

## 🔑 Step 5: Generate Secret Key

```bash
# Generate a secret key
mix phx.gen.secret

# Copy the generated key - you'll need it for the next step
```

## ⚙️ Step 6: Set Environment Variables

Set all required environment variables on Heroku:

```bash
# Phoenix Configuration
heroku config:set SECRET_KEY_BASE="your_generated_secret_key_here"
heroku config:set PHX_HOST="your-app-name.herokuapp.com"

# Google OAuth
heroku config:set GOOGLE_CLIENT_ID="your_google_client_id"
heroku config:set GOOGLE_CLIENT_SECRET="your_google_client_secret"

# Recall.ai
heroku config:set RECALL_AI_API_KEY="your_recall_ai_api_key"

# LinkedIn API
heroku config:set LINKEDIN_CLIENT_ID="your_linkedin_client_id"
heroku config:set LINKEDIN_CLIENT_SECRET="your_linkedin_client_secret"
heroku config:set LINKEDIN_REDIRECT_URI="https://your-app-name.herokuapp.com/auth/linkedin/callback"

# Facebook API
heroku config:set FACEBOOK_APP_ID="your_facebook_app_id"
heroku config:set FACEBOOK_APP_SECRET="your_facebook_app_secret"
heroku config:set FACEBOOK_REDIRECT_URI="https://your-app-name.herokuapp.com/auth/facebook/callback"
```

## 📦 Step 7: Prepare for Deployment

### Create Procfile
Create a `Procfile` in the root directory:

```bash
echo "web: MIX_ENV=prod mix phx.server" > Procfile
```

### Update package.json
Make sure your `assets/package.json` has the correct build script:

```json
{
  "scripts": {
    "deploy": "cd .. && mix assets.deploy && mix phx.digest"
  }
}
```

## 🚀 Step 8: Deploy to Heroku

```bash
# Add Heroku remote (if not already added)
git remote add heroku https://git.heroku.com/your-app-name.git

# Deploy to Heroku
git push heroku main

# Run database migrations
heroku run mix ecto.migrate

# Check if app is running
heroku ps
```

## 🔄 Step 9: Update Third-Party Redirect URIs

After deployment, update the redirect URIs in your third-party applications:

### Google OAuth Console
1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Navigate to APIs & Services > Credentials
3. Edit your OAuth 2.0 Client ID
4. Add authorized redirect URI: `https://your-app-name.herokuapp.com/auth/google/callback`

### LinkedIn Developer Portal
1. Go to [LinkedIn Developer Portal](https://developer.linkedin.com/)
2. Select your app
3. Go to Auth tab
4. Add redirect URI: `https://your-app-name.herokuapp.com/auth/linkedin/callback`

### Facebook Developers
1. Go to [Facebook Developers](https://developers.facebook.com/)
2. Select your app
3. Go to Facebook Login > Settings
4. Add redirect URI: `https://your-app-name.herokuapp.com/auth/facebook/callback`

### Recall.ai Dashboard
1. Go to [Recall.ai Dashboard](https://recall.ai/dashboard)
2. Navigate to Webhooks
3. Add webhook URL: `https://your-app-name.herokuapp.com/webhooks/recall`

## 🔍 Step 10: Verify Deployment

```bash
# Open your app in browser
heroku open

# Check logs
heroku logs --tail

# Check environment variables
heroku config
```

## 🛠️ Step 11: Post-Deployment Tasks

### Run Database Seeds (if needed)
```bash
heroku run mix run priv/repo/seeds.exs
```

### Check Database Connection
```bash
heroku run mix ecto.migrate
```

### Monitor Application
```bash
# View real-time logs
heroku logs --tail

# Check dyno status
heroku ps

# Scale dynos if needed
heroku ps:scale web=1
```

## 🔧 Troubleshooting

### Common Issues

#### 1. Build Failures
```bash
# Check build logs
heroku logs --tail

# Common fixes:
# - Ensure all dependencies are in mix.exs
# - Check that assets build correctly
# - Verify environment variables are set
```

#### 2. Database Connection Issues
```bash
# Check database status
heroku pg:info

# Reset database if needed
heroku pg:reset DATABASE_URL
heroku run mix ecto.migrate
```

#### 3. OAuth Redirect Issues
- Verify redirect URIs match exactly (including https)
- Check that environment variables are set correctly
- Ensure third-party apps are configured properly

#### 4. Memory Issues
```bash
# Check dyno memory usage
heroku logs --tail

# Scale up if needed
heroku ps:scale web=1:standard-1x
```

### Useful Commands

```bash
# View all environment variables
heroku config

# Set a new environment variable
heroku config:set NEW_VAR="value"

# Remove an environment variable
heroku config:unset VAR_NAME

# Run a one-off dyno
heroku run mix ecto.migrate

# Access database console
heroku pg:psql

# Restart all dynos
heroku restart

# View app info
heroku info
```

## 📊 Monitoring and Maintenance

### Log Management
```bash
# View recent logs
heroku logs

# Follow logs in real-time
heroku logs --tail

# View logs from specific dyno
heroku logs --dyno web.1
```

### Database Maintenance
```bash
# Backup database
heroku pg:backups:capture

# Download backup
heroku pg:backups:download

# Restore from backup
heroku pg:backups:restore BACKUP_URL
```

### Performance Monitoring
```bash
# Check dyno metrics
heroku ps

# Scale dynos
heroku ps:scale web=2

# Check addon status
heroku addons
```

## 🎉 Success!

Your PostMeet application should now be running on Heroku! 

- **App URL**: `https://your-app-name.herokuapp.com`
- **Admin Panel**: `https://your-app-name.herokuapp.com/dashboard`
- **Social Accounts**: `https://your-app-name.herokuapp.com/social-accounts`

## 📞 Support

If you encounter any issues during deployment:

1. Check the [Heroku Dev Center](https://devcenter.heroku.com/)
2. Review the troubleshooting section above
3. Check application logs: `heroku logs --tail`
4. Verify all environment variables are set correctly

## 🔄 Updates and Redeployment

To update your application:

```bash
# Make your changes
git add .
git commit -m "Update application"

# Deploy to Heroku
git push heroku main

# Run migrations if needed
heroku run mix ecto.migrate
```

That's it! Your PostMeet application is now live on Heroku! 🚀
