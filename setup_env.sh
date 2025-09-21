#!/bin/bash

# PostMeet Environment Variables Setup Script
# Run this script to set up your local development environment

echo "Setting up PostMeet environment variables..."

# Export environment variables for current session
export RECALL_AI_API_KEY="${RECALL_AI_API_KEY:-your_recall_ai_api_key_here}"
export LINKEDIN_CLIENT_ID="${LINKEDIN_CLIENT_ID:-your_linkedin_client_id_here}"
export LINKEDIN_CLIENT_SECRET="${LINKEDIN_CLIENT_SECRET:-your_linkedin_client_secret_here}"
export LINKEDIN_REDIRECT_URI="${LINKEDIN_REDIRECT_URI:-http://localhost:4000/auth/linkedin/callback}"
export FACEBOOK_APP_ID="${FACEBOOK_APP_ID:-your_facebook_app_id_here}"
export FACEBOOK_APP_SECRET="${FACEBOOK_APP_SECRET:-your_facebook_app_secret_here}"
export FACEBOOK_REDIRECT_URI="${FACEBOOK_REDIRECT_URI:-http://localhost:4000/auth/facebook/callback}"

echo "Environment variables set for current session."
echo ""
echo "To make these permanent, add them to your ~/.bashrc or ~/.zshrc:"
echo ""
echo "# PostMeet Environment Variables"
echo "export RECALL_AI_API_KEY=\"your_recall_ai_api_key_here\""
echo "export LINKEDIN_CLIENT_ID=\"your_linkedin_client_id_here\""
echo "export LINKEDIN_CLIENT_SECRET=\"your_linkedin_client_secret_here\""
echo "export LINKEDIN_REDIRECT_URI=\"http://localhost:4000/auth/linkedin/callback\""
echo "export FACEBOOK_APP_ID=\"your_facebook_app_id_here\""
echo "export FACEBOOK_APP_SECRET=\"your_facebook_app_secret_here\""
echo "export FACEBOOK_REDIRECT_URI=\"http://localhost:4000/auth/facebook/callback\""
echo ""
echo "Or run: source setup_env.sh"
