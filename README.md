# PostMeet - AI-Powered Meeting Content Generator

PostMeet is a full-stack Phoenix application that automatically generates social media posts and follow-up emails from meeting transcripts. It integrates with Google Calendar, Recall.ai for meeting recording and transcription, and social media platforms (LinkedIn, Facebook) for content distribution.

## 🚀 Features

- **Google Calendar Integration**: Automatically syncs meetings and attendees
- **AI-Powered Content Generation**: Creates social media posts and follow-up emails from meeting transcripts
- **Meeting Recording**: Integrates with Recall.ai for automatic meeting recording and transcription
- **Social Media Automation**: Post directly to LinkedIn and Facebook
- **Email Integration**: Generate and send follow-up emails via mailto links
- **Real-time Processing**: Automatic transcript processing and content generation
- **Modern UI**: Clean, responsive interface built with Tailwind CSS

## 🛠 Tech Stack

- **Backend**: Phoenix (Elixir)
- **Database**: PostgreSQL
- **Frontend**: Phoenix LiveView, Tailwind CSS
- **Authentication**: Google OAuth
- **APIs**: Google Calendar, Recall.ai, LinkedIn, Facebook
- **Deployment**: Production-ready

## 📋 Prerequisites

- Elixir 1.15+ and Erlang/OTP 25+
- PostgreSQL 13+
- Node.js 18+ (for assets)
- Git

## 🚀 Quick Start

### 1. Clone the Repository

```bash
git clone <your-repo-url>
cd post_meet
```

### 2. Install Dependencies

```bash
mix deps.get
cd assets && npm install && cd ..
```

### 3. Set Up Environment Variables

```bash
# Run the setup script to configure environment variables
source setup_env.sh

# Or manually set them:
export RECALL_AI_API_KEY="your_recall_ai_api_key"
export LINKEDIN_CLIENT_ID="your_linkedin_client_id"
export LINKEDIN_CLIENT_SECRET="your_linkedin_client_secret"
export FACEBOOK_APP_ID="your_facebook_app_id"
export FACEBOOK_APP_SECRET="your_facebook_app_secret"
```

### 4. Set Up Database

```bash
mix ecto.create
mix ecto.migrate
```

### 5. Start the Application

```bash
mix phx.server
```

Visit [http://localhost:4000](http://localhost:4000) in your browser.

## 🔧 Environment Variables

Create a `.env` file in the root directory:

```bash
# Database
DATABASE_URL=ecto://username:password@localhost/post_meet_dev

# Phoenix
SECRET_KEY_BASE=your_secret_key_here
PHX_HOST=localhost

# Google OAuth
GOOGLE_CLIENT_ID=your_google_client_id
GOOGLE_CLIENT_SECRET=your_google_client_secret

# Recall.ai
RECALL_AI_API_KEY=your_recall_ai_api_key

# LinkedIn API
LINKEDIN_CLIENT_ID=your_linkedin_client_id
LINKEDIN_CLIENT_SECRET=your_linkedin_client_secret
LINKEDIN_REDIRECT_URI=http://localhost:4000/auth/linkedin/callback

# Facebook API
FACEBOOK_APP_ID=your_facebook_app_id
FACEBOOK_APP_SECRET=your_facebook_app_secret
FACEBOOK_REDIRECT_URI=http://localhost:4000/auth/facebook/callback
```

### 5. Start the Server

```bash
mix phx.server
```

Visit [`localhost:4000`](http://localhost:4000) to see the application.

## 🔧 API Setup

### Google Calendar API
1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project or select existing
3. Enable Google Calendar API
4. Create OAuth 2.0 credentials
5. Add authorized redirect URI: `http://localhost:4000/auth/google/callback`

### Recall.ai API
1. Sign up at [Recall.ai](https://recall.ai/)
2. Get your API key from the dashboard
3. Configure webhook URL: `http://localhost:4000/webhooks/recall`

### LinkedIn API
1. Go to [LinkedIn Developer Portal](https://developer.linkedin.com/)
2. Create a new app
3. Add products: "Sign In with LinkedIn using OpenID Connect" and "Share on LinkedIn"
4. Configure redirect URI: `http://localhost:4000/auth/linkedin/callback`
5. Note down Client ID and Client Secret

### Facebook API
1. Go to [Facebook Developers](https://developers.facebook.com/)
2. Create a new app
3. Add Facebook Login product
4. Configure redirect URI: `http://localhost:4000/auth/facebook/callback`
5. Note down App ID and App Secret

## 📁 Project Structure

```
lib/
├── post_meet/
│   ├── ai/                    # AI content generation
│   ├── calendar/             # Google Calendar integration
│   ├── content/              # Content management
│   ├── recall/               # Recall.ai integration
│   └── social_media/         # Social media APIs
├── post_meet_web/
│   ├── controllers/          # Phoenix controllers
│   ├── components/           # LiveView components
│   └── plugs/                # Custom plugs
```

## 🔧 Development

### Running Tests

```bash
mix test
```

### Code Formatting

```bash
mix format
```

### Database Operations

```bash
# Create migration
mix ecto.gen.migration add_new_field

# Run migrations
mix ecto.migrate

# Rollback migration
mix ecto.rollback
```

## 📝 Environment Variables Reference

| Variable | Description | Required |
|----------|-------------|----------|
| `DATABASE_URL` | PostgreSQL connection string | Yes |
| `SECRET_KEY_BASE` | Phoenix secret key | Yes |
| `PHX_HOST` | Application hostname | Yes |
| `GOOGLE_CLIENT_ID` | Google OAuth client ID | Yes |
| `GOOGLE_CLIENT_SECRET` | Google OAuth client secret | Yes |
| `RECALL_AI_API_KEY` | Recall.ai API key | Yes |
| `LINKEDIN_CLIENT_ID` | LinkedIn app client ID | Yes |
| `LINKEDIN_CLIENT_SECRET` | LinkedIn app client secret | Yes |
| `LINKEDIN_REDIRECT_URI` | LinkedIn OAuth redirect URI | Yes |
| `FACEBOOK_APP_ID` | Facebook app ID | Yes |
| `FACEBOOK_APP_SECRET` | Facebook app secret | Yes |
| `FACEBOOK_REDIRECT_URI` | Facebook OAuth redirect URI | Yes |

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🆘 Support

If you encounter any issues or have questions, please:

1. Check the [Issues](https://github.com/your-username/post_meet/issues) page
2. Create a new issue with detailed information
3. Contact the maintainers

## 🙏 Acknowledgments

- [Phoenix Framework](https://phoenixframework.org/)
- [Recall.ai](https://recall.ai/) for meeting recording
- [Google Calendar API](https://developers.google.com/calendar)
- [LinkedIn API](https://developer.linkedin.com/)
- [Facebook API](https://developers.facebook.com/)