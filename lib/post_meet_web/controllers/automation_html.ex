defmodule PostMeetWeb.AutomationHTML do
  @moduledoc """
  This module contains pages rendered by AutomationController.

  See the `automation_html` directory for all templates available.
  """
  use PostMeetWeb, :html

  embed_templates "automation_html/*"
end

