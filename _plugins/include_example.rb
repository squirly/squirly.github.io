class IncludeExample < Liquid::Tag
  @@gists = {}

  def initialize(tag_name, text, tokens)
    super
    @file = /"(.*)"/.match(text)[1]
  end

  def render(context)
    gist_id = context.environments.first["page"]["gist"]
    gist = get_gist(gist_id)

    if gist.is_a?(String)
      "Could not load gist: #{gist}"
    else
      filename = get_files(gist).select{|f| f.start_with?(@file)}.first
      "<script src=\"#{gist['html_url']}.js?file=#{filename}\"></script>"
    end
  end

  def get_gist(gist_id)
    if !@@gists.key?(gist_id)
      gist = JSON.parse(Net::HTTP.get(URI("https://api.github.com/gists/#{gist_id}")))
      if gist['message'] && gist['message'].start_with?("Test")
        return "GIST API LIMIT REACHED"
      end
      @@gists[gist_id] = gist
    end
    @@gists[gist_id]
  end

  def get_files(gist)
    gist['files'].values.map{|f| f['filename']}
  end
end

Liquid::Template.register_tag('include_example', IncludeExample)
