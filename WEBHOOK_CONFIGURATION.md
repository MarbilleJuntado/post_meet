# Recall.ai Webhook Configuration

To enable automatic transcript processing, you need to configure Recall.ai to send webhook notifications to your application.

## Webhook Endpoint

Your application has a webhook endpoint configured at:
```
POST /webhooks/recall
```

## Configuration Steps

### 1. Set up your webhook URL

If running locally:
```
http://localhost:4000/webhooks/recall
```

If deployed (replace with your domain):
```
https://your-domain.com/webhooks/recall
```

### 2. Configure in Recall.ai Dashboard

1. Go to your Recall.ai dashboard
2. Navigate to Settings → Webhooks
3. Add a new webhook with:
   - **URL**: Your webhook endpoint URL
   - **Events**: Select the following events:
     - `bot.recording_ready`
     - `bot.transcript_ready` 
     - `transcript.done`
     - `bot.status_changed`

### 3. Test the webhook

You can test the webhook by manually triggering transcript processing:

```elixir
# In IEx console
PostMeet.Recall.RecallService.process_pending_transcripts()

# Or for a specific meeting
PostMeet.Recall.RecallService.process_meeting_transcript(meeting_id)
```

## How It Works

1. **Bot joins meeting** → Recall.ai sends `bot.status_changed` webhook
2. **Recording starts** → Recall.ai sends `bot.recording_ready` webhook  
3. **Transcript ready** → Recall.ai sends `transcript.done` webhook
4. **Your app processes** → Automatically downloads and stores transcript

## Manual Processing

If webhooks fail or are missed, you can manually process transcripts:

```elixir
# Process all pending transcripts
PostMeet.Recall.RecallService.process_pending_transcripts()

# Process specific meeting
PostMeet.Recall.RecallService.process_meeting_transcript(14)
```

## Troubleshooting

- Check webhook logs in your application
- Verify webhook URL is accessible from Recall.ai
- Ensure webhook events are properly configured
- Use manual processing as fallback
