defmodule PostMeetWeb.ContentHTML do
  @moduledoc """
  This module contains pages rendered by ContentController.

  See the `content_html` directory for all templates available.
  """
  use PostMeetWeb, :html

  embed_templates "content_html/*"
end
