defmodule Elixirschool.Content.Lesson do
  @headers_regex ~r/<(h2|h3|h4)>([\w\s?!\.\/\d]+)<\/(?:h2|h3|h4)>/

  @enforce_keys [:body, :section, :locale, :name, :title, :version]
  defstruct [
    :body,
    :section,
    :locale,
    :name,
    :next,
    :previous,
    :title,
    :version,
    :redirect_from
  ]

  def build(filename, attrs, body) do
    [locale, section, name] =
      filename
      |> Path.rootname()
      |> Path.split()
      |> Enum.take(-3)

    filename_attrs = [
      body: add_table_of_contents(body),
      section: String.to_atom(section),
      locale: locale,
      name: String.to_atom(name)
    ]

    struct!(__MODULE__, filename_attrs ++ Map.to_list(attrs))
  end

  defp link_fragment(name) do
    name
    |> String.trim()
    |> String.downcase()
    |> String.replace(" ", "-")
  end

  defp page_link(name) do
    "<a href=\"##{link_fragment(name)}\">#{name}</a>"
  end

  defp add_table_of_contents(body) do
    toc_html = table_of_contents_html(body)

    body = String.replace(body, "{% include toc.html %}", toc_html)

    Regex.replace(@headers_regex, body, fn _, header, name, _ ->
      fragment = link_fragment(name)

      "<#{header} id=\"#{fragment}\">#{name}</#{header}>"
    end)
  end

  defp table_of_contents_html(body) do
    {html, _} =
      @headers_regex
      |> Regex.scan(body)
      |> Enum.reduce({"<div><ul class=\"table_of_contents\">", nil}, fn [_, "h" <> size, name], {html, header} ->
        section_link =
          name
          |> String.trim()
          |> page_link()

        size = String.to_integer(size)

        cond do
          is_nil(header) ->
            {"#{html}<li>#{section_link}", size}

          size == header ->
            {"#{html}</li><li>#{section_link}", size}

          size < header ->
            closing_tag =
              1..(header - size)
              |> Enum.map(fn _ -> "</ul>" end)
              |> Enum.join("")

            {"#{html}</li>#{closing_tag}</li><li>#{section_link}", size}

          size > header ->
            {"#{html}<ul><li>#{section_link}", size}
        end
      end)

    "#{html}</ul></div>"
  end
end
