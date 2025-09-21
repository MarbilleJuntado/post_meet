# 🔗 Social Media API Setup Guide

This guide will help you set up Facebook and LinkedIn API integrations for PostMeet.

## 📋 **Required API Keys**

You'll need to set up the following environment variables:

### **LinkedIn API Keys**
```bash
export LINKEDIN_CLIENT_ID="your_linkedin_client_id"
export LINKEDIN_CLIENT_SECRET="your_linkedin_client_secret"
export LINKEDIN_REDIRECT_URI="http://localhost:4000/auth/linkedin/callback"
```

### **Facebook API Keys**
```bash
export FACEBOOK_APP_ID="your_facebook_app_id"
export FACEBOOK_APP_SECRET="your_facebook_app_secret"
export FACEBOOK_REDIRECT_URI="http://localhost:4000/auth/facebook/callback"
```

---

## 🔵 **LinkedIn API Setup**

### **1. Create LinkedIn App**
1. **Go to**: [https://www.linkedin.com/developers/](https://www.linkedin.com/developers/)
2. **Sign in** with your LinkedIn account
3. **Create a new app**:
   - App name: `PostMeet Integration`
   - LinkedIn Page: Select your company page (optional)
   - App logo: Upload your app logo
   - Legal agreement: Accept terms

### **2. Get LinkedIn API Keys**
After creating your app, you'll find:
- **Client ID** (App ID) - Use this for `LINKEDIN_CLIENT_ID`
- **Client Secret** (App Secret) - Use this for `LINKEDIN_CLIENT_SECRET`

### **3. Configure LinkedIn App**
1. **Go to Auth tab** in your LinkedIn app
2. **Add redirect URI**: `http://localhost:4000/auth/linkedin/callback`
3. **Request these scopes**:
   - `r_liteprofile` - Basic profile information
   - `r_emailaddress` - Email address
   - `w_member_social` - Post content to LinkedIn

### **4. LinkedIn API Endpoints**
- **OAuth URL**: `https://www.linkedin.com/oauth/v2/authorization`
- **Token URL**: `https://www.linkedin.com/oauth/v2/accessToken`
- **Profile URL**: `https://api.linkedin.com/v2/people/~`
- **Post URL**: `https://api.linkedin.com/v2/ugcPosts`

---

## 🔵 **Facebook API Setup**

### **1. Create Facebook App**
1. **Go to**: [https://developers.facebook.com/](https://developers.facebook.com/)
2. **Sign in** with your Facebook account
3. **Create a new app**:
   - App type: `Business`
   - App name: `PostMeet Integration`
   - Contact email: Your email

### **2. Get Facebook API Keys**
After creating your app, you'll find:
- **App ID** (Client ID) - Use this for `FACEBOOK_APP_ID`
- **App Secret** (Client Secret) - Use this for `FACEBOOK_APP_SECRET`

### **3. Configure Facebook App**
1. **Go to Facebook Login** in your app
2. **Add redirect URI**: `http://localhost:4000/auth/facebook/callback`
3. **Request these scopes**:
   - `email` - User email
   - `public_profile` - Basic profile information
   - `pages_manage_posts` - Post to Facebook pages
   - `pages_read_engagement` - Read page insights

### **4. Facebook API Endpoints**
- **OAuth URL**: `https://www.facebook.com/v18.0/dialog/oauth`
- **Token URL**: `https://graph.facebook.com/v18.0/oauth/access_token`
- **Profile URL**: `https://graph.facebook.com/v18.0/me`
- **Post URL**: `https://graph.facebook.com/v18.0/{page-id}/feed`

---

## ⚙️ **Configuration**

### **1. Add to config/dev.exs**
```elixir
config :post_meet,
  linkedin_client_id: System.get_env("LINKEDIN_CLIENT_ID"),
  linkedin_client_secret: System.get_env("LINKEDIN_CLIENT_SECRET"),
  linkedin_redirect_uri: System.get_env("LINKEDIN_REDIRECT_URI", "http://localhost:4000/auth/linkedin/callback"),
  facebook_app_id: System.get_env("FACEBOOK_APP_ID"),
  facebook_app_secret: System.get_env("FACEBOOK_APP_SECRET"),
  facebook_redirect_uri: System.get_env("FACEBOOK_REDIRECT_URI", "http://localhost:4000/auth/facebook/callback")
```

### **2. Set Environment Variables**
```bash
# LinkedIn
export LINKEDIN_CLIENT_ID="your_linkedin_client_id"
export LINKEDIN_CLIENT_SECRET="your_linkedin_client_secret"
export LINKEDIN_REDIRECT_URI="http://localhost:4000/auth/linkedin/callback"

# Facebook
export FACEBOOK_APP_ID="your_facebook_app_id"
export FACEBOOK_APP_SECRET="your_facebook_app_secret"
export FACEBOOK_REDIRECT_URI="http://localhost:4000/auth/facebook/callback"
```

### **3. Restart the Server**
```bash
mix phx.server
```

---

## 🧪 **Testing the Integration**

### **1. Connect Social Accounts**
1. **Go to**: http://localhost:4000/social-accounts
2. **Click "Connect LinkedIn"** or **"Connect Facebook"**
3. **Authorize** the app on the respective platform
4. **Verify** the account appears in your connected accounts

### **2. Test Content Posting**
1. **Go to a meeting** with generated content
2. **Click "Post"** on a social media post
3. **Check** that the content is posted to your social media account

### **3. Verify Posting**
- **LinkedIn**: Check your LinkedIn feed for the posted content
- **Facebook**: Check your Facebook page/feed for the posted content

---

## 🔧 **Troubleshooting**

### **Common Issues**

#### **"Invalid redirect URI"**
- **LinkedIn**: Make sure the redirect URI in your LinkedIn app matches exactly: `http://localhost:4000/auth/linkedin/callback`
- **Facebook**: Make sure the redirect URI in your Facebook app matches exactly: `http://localhost:4000/auth/facebook/callback`

#### **"Invalid client credentials"**
- Double-check your API keys are correct
- Make sure you're using the right environment variables

#### **"Insufficient permissions"**
- **LinkedIn**: Make sure you've requested the `w_member_social` scope
- **Facebook**: Make sure you've requested the `pages_manage_posts` scope

#### **"Token expired"**
- Reconnect your social media account
- The app will automatically handle token refresh

### **Debug Steps**
1. **Check environment variables**: `echo $LINKEDIN_CLIENT_ID`
2. **Check server logs**: Look for API errors in the console
3. **Test API endpoints**: Use curl to test the APIs directly
4. **Check app permissions**: Verify scopes are correctly configured

---

## 🚀 **Production Setup**

### **1. Update Redirect URIs**
For production, update the redirect URIs to:
- **LinkedIn**: `https://yourdomain.com/auth/linkedin/callback`
- **Facebook**: `https://yourdomain.com/auth/facebook/callback`

### **2. Environment Variables**
Set the production environment variables on your server:
```bash
export LINKEDIN_CLIENT_ID="your_production_linkedin_client_id"
export LINKEDIN_CLIENT_SECRET="your_production_linkedin_client_secret"
export LINKEDIN_REDIRECT_URI="https://yourdomain.com/auth/linkedin/callback"

export FACEBOOK_APP_ID="your_production_facebook_app_id"
export FACEBOOK_APP_SECRET="your_production_facebook_app_secret"
export FACEBOOK_REDIRECT_URI="https://yourdomain.com/auth/facebook/callback"
```

### **3. SSL Certificate**
Make sure your production server has a valid SSL certificate, as both LinkedIn and Facebook require HTTPS for OAuth.

---

## 📚 **Additional Resources**

- **LinkedIn API Documentation**: [https://docs.microsoft.com/en-us/linkedin/](https://docs.microsoft.com/en-us/linkedin/)
- **Facebook API Documentation**: [https://developers.facebook.com/docs/](https://developers.facebook.com/docs/)
- **OAuth 2.0 Guide**: [https://oauth.net/2/](https://oauth.net/2/)

---

## ✅ **Success Checklist**

- [ ] LinkedIn app created and configured
- [ ] Facebook app created and configured
- [ ] API keys set in environment variables
- [ ] Redirect URIs configured correctly
- [ ] Required scopes requested
- [ ] Server restarted with new configuration
- [ ] Social accounts can be connected
- [ ] Content can be posted to social media
- [ ] Posted content appears on social media platforms
