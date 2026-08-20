#!/usr/bin/env ruby
# frozen_string_literal: true

require "date"
require "fileutils"
require "optparse"
require "pathname"
require "yaml"

REPO_ROOT = File.expand_path("..", __dir__)
MANIFEST_PATH = File.join(REPO_ROOT, ".blog", "sources.yml")

class PublishError < StandardError; end

class BlogPublisher
  def initialize(manifest_path = MANIFEST_PATH)
    @manifest_path = File.expand_path(manifest_path)
    @repo_root = File.expand_path("..", File.dirname(@manifest_path))
    @manifest = load_manifest
  end

  def publish(source_arg, requested_id: nil)
    source_path = resolve_source(source_arg)
    data, content = read_post(source_path)
    id = requested_id || data["blog_id"] || infer_id(source_path)
    validate_id!(id)

    if data["blog_id"] && data["blog_id"].to_s != id.to_s
      raise PublishError, "#{source_path} 的 blog_id 与指定 ID 不一致"
    end

    existing = find_entry(id)
    output = existing && existing["output"]
    output ||= "_posts/#{date_from(data)}-#{id}.md"
    ensure_output_available!(output, id)

    entry = (existing || {}).merge(
      "id" => id,
      "source" => relative_source(source_path),
      "output" => output,
      "status" => "published"
    )

    write_output(output, render_content(content, data, id))
    replace_entry(entry)
    save_manifest
    puts "published #{id} -> #{output}"
  end

  def sync
    entries = published_entries
    entries.each do |entry|
      id = entry.fetch("id")
      source_path = resolve_source(entry.fetch("source"))
      data, content = read_post(source_path)
      validate_id!(id)

      if data["blog_id"] && data["blog_id"].to_s != id.to_s
        raise PublishError, "#{source_path} 的 blog_id 与索引中的 #{id} 不一致"
      end

      output = entry["output"] || "_posts/#{date_from(data)}-#{id}.md"
      ensure_output_available!(output, id)
      entry["output"] = output
      write_output(output, render_content(content, data, id))
      puts "synced #{id} -> #{output}"
    end
    save_manifest
  end

  def check
    failures = []

    published_entries.each do |entry|
      id = entry.fetch("id")
      begin
        source_path = resolve_source(entry.fetch("source"))
        data, content = read_post(source_path)
        validate_id!(id)
        output = entry.fetch("output")
        expected = render_content(content, data, id)
        actual_path = output_file(output)

        if !File.file?(actual_path)
          failures << "missing #{output}"
        elsif File.binread(actual_path).b != expected.b
          failures << "outdated #{output}"
        end
      rescue KeyError, PublishError, Errno::ENOENT => e
        failures << "#{id}: #{e.message}"
      end
    end

    if failures.empty?
      puts "blog sources are up to date"
      true
    else
      failures.each { |failure| warn failure }
      false
    end
  end

  private

  def load_manifest
    return { "source_root" => "../..", "posts" => [] } unless File.file?(@manifest_path)

    manifest = YAML.safe_load(File.read(@manifest_path), aliases: false) || {}
    raise PublishError, "#{@manifest_path} 必须是 YAML 对象" unless manifest.is_a?(Hash)

    manifest["source_root"] ||= "../.."
    manifest["posts"] ||= []
    raise PublishError, "#{@manifest_path} 的 posts 必须是数组" unless manifest["posts"].is_a?(Array)

    manifest
  rescue Psych::Exception => e
    raise PublishError, "无法读取 #{@manifest_path}: #{e.message}"
  end

  def source_root
    root = File.expand_path(@manifest.fetch("source_root"), @repo_root)
    File.realpath(root)
  rescue Errno::ENOENT
    root
  end

  def resolve_source(source)
    path = Pathname.new(source.to_s)
    resolved = if path.absolute?
                 path.to_s
               else
                 File.join(source_root, path.to_s)
               end
    resolved = File.expand_path(resolved)
    raise PublishError, "找不到源文件: #{resolved}" unless File.file?(resolved)

    File.realpath(resolved)
  end

  def relative_source(path)
    relative = Pathname.new(path).relative_path_from(Pathname.new(source_root)).to_s
    if relative == ".." || relative.start_with?("../")
      raise PublishError, "源文件必须位于 source_root 内: #{path}"
    end

    relative
  end

  def read_post(path)
    content = File.read(path, encoding: "UTF-8").gsub("\r\n", "\n")
    match = content.match(/\A---\n(.*?)\n---(?:\n|\z)/m)
    raise PublishError, "#{path} 缺少 YAML front matter" unless match

    data = YAML.safe_load(
      match[1],
      permitted_classes: [Date, Time],
      aliases: false
    ) || {}
    raise PublishError, "#{path} 的 front matter 必须是 YAML 对象" unless data.is_a?(Hash)

    validate_metadata!(path, data)
    [data, content]
  rescue Psych::Exception => e
    raise PublishError, "#{path} 的 front matter 无法解析: #{e.message}"
  end

  def validate_metadata!(path, data)
    raise PublishError, "#{path} 缺少 title" if data["title"].to_s.strip.empty?
    date_from(data)
  end

  def date_from(data)
    value = data["date"].to_s
    match = value.match(/\A\d{4}-\d{2}-\d{2}/)
    raise PublishError, "文章 date 必须以 YYYY-MM-DD 开头" unless match

    match[0]
  end

  def infer_id(path)
    File.basename(path, ".md").downcase.gsub(/[^a-z0-9]+/, "-").sub(/\A-+/, "").sub(/-+\z/, "")
  end

  def validate_id!(id)
    unless id && id.to_s.match?(/\A[a-zA-Z0-9][a-zA-Z0-9_-]*\z/)
      raise PublishError, "blog_id 只能包含字母、数字、下划线和连字符: #{id.inspect}"
    end
  end

  def render_content(content, data, id)
    additions = []
    additions << "blog_id: #{id}" unless data.key?("blog_id")
    additions << "permalink: /posts/#{id}/" if data["permalink"].to_s.strip.empty?
    return content if additions.empty?

    content.sub("---\n", "---\n#{additions.join("\n")}\n")
  end

  def find_entry(id)
    @manifest["posts"].find { |entry| entry["id"].to_s == id.to_s }
  end

  def published_entries
    @manifest["posts"].select { |entry| entry.fetch("status", "published") == "published" }
  end

  def replace_entry(entry)
    @manifest["posts"].reject! { |item| item["id"].to_s == entry["id"].to_s }
    @manifest["posts"] << entry
  end

  def output_file(relative_path)
    path = File.expand_path(relative_path.to_s, @repo_root)
    prefix = "#{@repo_root}#{File::SEPARATOR}"
    raise PublishError, "发布目标必须位于博客仓库内: #{relative_path}" unless path.start_with?(prefix)

    path
  end

  def ensure_output_available!(relative_path, id)
    conflict = @manifest["posts"].find do |entry|
      entry["output"].to_s == relative_path.to_s && entry["id"].to_s != id.to_s
    end
    return unless conflict

    raise PublishError, "#{relative_path} 已被文章 #{conflict['id']} 使用"
  end

  def write_output(relative_path, content)
    path = output_file(relative_path)
    FileUtils.mkdir_p(File.dirname(path))
    return if File.file?(path) && File.binread(path).b == content.b

    File.write(path, content, encoding: "UTF-8")
  end

  def save_manifest
    FileUtils.mkdir_p(File.dirname(@manifest_path))
    File.write(@manifest_path, YAML.dump(@manifest), encoding: "UTF-8")
  end
end

def print_help
  puts <<~HELP
    Usage:
      bundle exec ruby tools/publish_posts.rb publish SOURCE [--id ID]
      bundle exec ruby tools/publish_posts.rb sync
      bundle exec ruby tools/publish_posts.rb check

    SOURCE 可以是绝对路径，也可以是相对于 .blog/sources.yml 中 source_root 的路径。
  HELP
end

command = ARGV.shift
publisher = BlogPublisher.new

begin
  case command
  when "publish"
    options = {}
    parser = OptionParser.new do |opts|
      opts.on("--id ID", "稳定的 blog_id") { |value| options[:id] = value }
    end
    parser.parse!(ARGV)
    source = ARGV.shift
    raise PublishError, "publish 需要 SOURCE" unless source

    publisher.publish(source, requested_id: options[:id])
  when "sync"
    publisher.sync
  when "check"
    exit(publisher.check ? 0 : 1)
  else
    print_help
    exit(1)
  end
rescue OptionParser::ParseError, PublishError, KeyError, Errno::ENOENT => e
  warn "publish_posts: #{e.message}"
  exit(1)
end
