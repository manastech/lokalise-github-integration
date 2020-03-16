require "kemal"

LOKALISE_X_SECRET = ENV["LOKALISE_X_SECRET"]
GITHUB_TOKEN      = ENV["GITHUB_TOKEN"]
GITHUB_ORG_REPO   = ENV["GITHUB_ORG_REPO"]
DEBOUNCE          = ENV["DEBOUNCE"]?.try(&.to_i) || 10

Kemal.config.port = ENV["PORT"]?.try(&.to_i) || 3000

class Queue
  @mutex = Mutex.new
  @requests = Hash(String, Concurrent::Future(Nil)?).new

  def enqueue(lang : String)
    @mutex.synchronize do
      @requests[lang]?.try &.cancel
      @requests[lang] = delay(DEBOUNCE.seconds) { trigger(lang) }
    end
  end

  def trigger(lang : String) : Nil
    @mutex.synchronize do
      @requests[lang]?.try &.cancel
      @requests[lang] = nil
    end

    puts "Triggering #{lang}!"

    HTTP::Client.post("https://api.github.com/repos/#{GITHUB_ORG_REPO}/dispatches",
      headers: HTTP::Headers{"Authorization" => "token #{GITHUB_TOKEN}"},
      body: %q({"event_type": "translation-updated", "client_payload": {"lang": "#{lang}"}})) do |response|
      begin
        puts response.body_io.gets
      rescue
        puts "Unable to show request body https://github.com/crystal-lang/crystal/issues/8461 ?"
      end
      puts "Request to GitHub finished"
    end
  end
end

Q = Queue.new

get "/" do
  render "src/views/index.html.ecr"
end

post "/trigger" do |env|
  language = env.params.body["language"].as(String)
  Q.trigger(language)
  env.redirect "/"
end

post "/lokalise" do |env|
  secret = env.request.headers["X-Secret"]
  if secret == LOKALISE_X_SECRET
    begin
      language = env.params.json["language"].as(Hash(String, JSON::Any))["iso"].as_s
      puts "Enqueue #{language}"
      Q.enqueue(language)
    rescue e
      # catch exception and continue response to allow validation requests of lokalise
      puts e
    end
  else
    puts "Invalid X-Secret header"
  end
end

Kemal.run
