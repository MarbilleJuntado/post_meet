# 🔑 Recall.ai API Key Setup Guide

## Step 1: Get Your Recall.ai API Key

1. **Visit Recall.ai**: Go to [https://www.recall.ai/](https://www.recall.ai/)
2. **Sign Up**: Create an account with your email
3. **Verify Email**: Check your email and verify your account
4. **Get API Key**: 
   - Go to your Dashboard
   - Look for "API Keys" or "Developer" section
   - Click "Generate API Key" or "Create New Key"
   - Copy the generated key (starts with `recall_`)

## Step 2: Set Your API Key

### Option A: Environment Variable (Recommended)
```bash
export RECALL_AI_API_KEY="your_actual_api_key_here"
```

### Option B: Add to your shell profile
Add this line to your `~/.bashrc` or `~/.zshrc`:
```bash
export RECALL_AI_API_KEY="your_actual_api_key_here"
```

### Option C: Create a .env file
Create a `.env` file in your project root:
```
RECALL_AI_API_KEY=your_actual_api_key_here
```

## Step 3: Test the Integration

1. **Start the server**:
   ```bash
   mix phx.server
   ```

2. **Go to your dashboard**: http://localhost:4000/dashboard

3. **Toggle a notetaker checkbox** on any meeting

4. **Check the logs** to see if the bot scheduling works

## Step 4: Verify Webhook Setup

For production, you'll need to configure webhooks:

1. **Get your webhook URL**: `https://yourdomain.com/webhooks/recall`
2. **Add to Recall.ai**: In your Recall.ai dashboard, add this webhook URL
3. **Test webhook**: Recall.ai will send test events to verify the connection

## Troubleshooting

- **"API key not set" error**: Make sure you've exported the environment variable
- **"Invalid API key" error**: Double-check your API key in Recall.ai dashboard
- **Webhook not working**: Ensure your server is accessible from the internet

## Next Steps

Once you have your API key set up:
1. Toggle notetaker on a meeting
2. The bot will be scheduled to join X minutes before the meeting
3. After the meeting, you'll get recordings and transcripts automatically




