defmodule PostMeet.AI.ContentGenerator do
  @moduledoc """
  AI-powered content generation service for creating social media posts and emails
  from meeting transcripts.
  """

  @doc """
  Generates a social media post from a meeting transcript.
  """
  def generate_social_post(transcript, platform, automation_config \\ %{}) do
    _prompt = build_social_post_prompt(transcript, platform, automation_config)

    # For now, we'll use a rule-based approach since we don't have OpenAI API set up
    # In production, this would call OpenAI's API
    content = generate_content_with_rules(transcript, platform, "social_post")

    {:ok, content}
  end

  @doc """
  Generates a follow-up email from a meeting transcript.
  """
  def generate_follow_up_email(transcript, automation_config \\ %{}) do
    _prompt = build_email_prompt(transcript, automation_config)

    # For now, we'll use a rule-based approach
    content = generate_content_with_rules(transcript, "email", "follow_up_email")

    {:ok, content}
  end

  @doc """
  Extracts key insights from a meeting transcript.
  """
  def extract_insights(transcript) do
    # Extract key topics, decisions, and action items
    topics = extract_topics(transcript)
    decisions = extract_decisions(transcript)
    action_items = extract_action_items(transcript)

    %{
      topics: topics,
      decisions: decisions,
      action_items: action_items,
      summary: generate_summary(transcript)
    }
  end

  # Private functions for content generation

  defp build_social_post_prompt(transcript, platform, config) do
    """
    Generate a professional #{platform} post based on this meeting transcript:

    #{transcript}

    Requirements:
    - Keep it engaging and professional
    - Include relevant hashtags
    - Highlight key insights or takeaways
    - Platform: #{platform}
    - Tone: #{config[:tone] || "professional"}
    - Max length: #{config[:max_length] || 280} characters
    """
  end

  defp build_email_prompt(transcript, _config) do
    """
    Generate a professional follow-up email based on this meeting transcript:

    #{transcript}

    Requirements:
    - Professional and courteous tone
    - Include meeting summary
    - Highlight next steps or action items
    - Keep it concise but comprehensive
    """
  end

  defp generate_content_with_rules(transcript, platform, content_type) do
    insights = extract_insights(transcript)

    case content_type do
      "social_post" -> build_social_post_content(insights, platform)
      "follow_up_email" -> build_email_content(insights)
    end
  end

  defp build_social_post_content(insights, platform) do
    # Extract the most interesting topic or decision
    main_topic = insights.topics |> List.first() || "productive discussion"
    key_decision = insights.decisions |> List.first()

    hashtags = get_platform_hashtags(platform)

    # Create more specific content based on actual transcript content
    if key_decision && key_decision != "No specific decisions were recorded" do
      """
      🎯 Great meeting today! We made an important decision: #{key_decision}

      Key topics covered: #{Enum.join(insights.topics, ", ")}

      #{hashtags}
      """
    else
      # Use the actual summary from the transcript
      summary_text = if insights.summary && insights.summary != "We had a productive discussion covering various topics and next steps." do
        String.slice(insights.summary, 0, 100) <> "..."
      else
        "We had a productive discussion covering various topics and next steps."
      end

      """
      💡 Productive discussion on #{main_topic} today!

      #{summary_text}

      Key insights: #{Enum.join(insights.topics, ", ")}

      #{hashtags}
      """
    end
  end

  defp build_email_content(insights) do
    """
    Subject: Follow-up from our meeting

    Hi there,

    Thank you for taking the time to meet with me today. I wanted to follow up on our discussion and provide a summary of what we covered.

    ## Meeting Summary
    #{insights.summary}

    ## Key Topics Discussed
    #{Enum.join(insights.topics, "\n• ")}

    ## Decisions Made
    #{if insights.decisions != [], do: Enum.join(insights.decisions, "\n• "), else: "No major decisions were made."}

    ## Next Steps
    #{if insights.action_items != [], do: Enum.join(insights.action_items, "\n• "), else: "No specific action items were identified."}

    Please let me know if you have any questions or if there's anything else I can help you with.

    Best regards,
    """
  end

  defp extract_topics(transcript) do
    # More sophisticated keyword extraction based on actual transcript content
    # Look for meaningful words and phrases
    meaningful_words = transcript
    |> String.downcase()
    |> String.split(~r/\W+/)
    |> Enum.filter(&(String.length(&1) > 4))
    |> Enum.filter(&(&1 not in ["meeting", "discussion", "today", "think", "going", "right", "know", "like", "just", "really", "well", "good", "great", "thanks", "thank"]))
    |> Enum.frequencies()
    |> Enum.sort_by(fn {_word, count} -> count end, :desc)
    |> Enum.take(8)
    |> Enum.map(fn {word, _count} -> String.capitalize(word) end)

    # Extract key phrases that might indicate topics
    topic_phrases = extract_topic_phrases(transcript)

    # Combine meaningful words with topic phrases
    all_topics = (meaningful_words ++ topic_phrases)
    |> Enum.uniq()
    |> Enum.take(5)

    # If we don't have enough topics, add some generic ones
    if length(all_topics) < 2 do
      all_topics ++ ["Discussion", "Planning", "Collaboration"]
    else
      all_topics
    end
  end

  defp extract_topic_phrases(transcript) do
    # Look for common business/meeting phrases
    topic_patterns = [
      ~r/\b(?:strategy|strategic|strategic planning)\b/i,
      ~r/\b(?:product|product development|product roadmap)\b/i,
      ~r/\b(?:marketing|marketing strategy|marketing plan)\b/i,
      ~r/\b(?:sales|sales process|sales strategy)\b/i,
      ~r/\b(?:budget|budget planning|financial)\b/i,
      ~r/\b(?:team|team building|team management)\b/i,
      ~r/\b(?:customer|customer experience|customer service)\b/i,
      ~r/\b(?:technology|tech|technical|digital)\b/i,
      ~r/\b(?:innovation|innovative|innovation strategy)\b/i,
      ~r/\b(?:growth|business growth|growth strategy)\b/i
    ]

    topics = for pattern <- topic_patterns do
      case Regex.run(pattern, transcript) do
        [match] -> String.capitalize(match)
        nil -> nil
      end
    end
    |> Enum.filter(&(&1 != nil))
    |> Enum.uniq()

    topics
  end

  defp extract_decisions(transcript) do
    # Look for decision-making language
    decision_patterns = [
      ~r/we decided/i,
      ~r/we agreed/i,
      ~r/we concluded/i,
      ~r/we will/i,
      ~r/we should/i,
      ~r/let's/i
    ]

    decisions = for pattern <- decision_patterns do
      Regex.scan(pattern, transcript)
      |> List.flatten()
    end
    |> List.flatten()
    |> Enum.uniq()
    |> Enum.take(2)

    if decisions == [] do
      ["No specific decisions were recorded"]
    else
      decisions
    end
  end

  defp extract_action_items(transcript) do
    # Look for action-oriented language
    action_patterns = [
      ~r/we need to/i,
      ~r/next steps/i,
      ~r/follow up/i,
      ~r/action item/i,
      ~r/todo/i
    ]

    actions = for pattern <- action_patterns do
      Regex.scan(pattern, transcript)
      |> List.flatten()
    end
    |> List.flatten()
    |> Enum.uniq()
    |> Enum.take(3)

    if actions == [] do
      ["Schedule follow-up meeting"]
    else
      actions
    end
  end

  defp generate_summary(transcript) do
    # More intelligent summary generation
    sentences = transcript
    |> String.split(~r/[.!?]+/)
    |> Enum.map(&String.trim/1)
    |> Enum.filter(&(String.length(&1) > 20))
    |> Enum.filter(&(String.length(&1) < 200))  # Filter out very long sentences
    |> Enum.take(3)

    if length(sentences) > 0 do
      # Clean up the sentences and join them
      cleaned_sentences = sentences
      |> Enum.map(&String.trim/1)
      |> Enum.filter(&(&1 != ""))

      if length(cleaned_sentences) > 0 do
        Enum.join(cleaned_sentences, ". ") <> "."
      else
        "We had a productive discussion covering various topics and next steps."
      end
    else
      "We had a productive discussion covering various topics and next steps."
    end
  end

  defp get_platform_hashtags(platform) do
    case platform do
      "linkedin" -> "#ProfessionalGrowth #MeetingInsights #Collaboration #BusinessStrategy"
      "facebook" -> "#Meeting #Business #Professional #Growth"
      "twitter" -> "#Meeting #Business #Professional"
      _ -> "#Meeting #Business #Professional"
    end
  end
end
