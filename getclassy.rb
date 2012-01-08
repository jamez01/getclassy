#!/usr/bin/env ruby
require 'optparse'

module GetClassy
  class CLI
    attr_accessor :options, :gems, :app,:opts
    def run
      @opts = parse_args
      # Validation:
      (puts opts.banner ; exit) if ARGV.empty? or ARGV.count > 1
      (@opts.warn "File / Directory named #{@app} already exists.";exit) if File.exists?("./#{@app}")
      init_dirs
      gen_files
      write_files
      do_git
    end
    def initialize(opts = {}, gems = [])
      @options = { :configru => true, :bundler => true, :git => true, :db => :dm,:view => 'erb' }.merge(opts)
      @gems=['sinatra']
      @gems << (gems - @gems)
    end
    private
    def parse_args
      opts = OptionParser.new
      opts.banner = "Usage: #{__FILE__} [options] app_name"
      opts.on('-c', '--no-configru', 'Do not generate config.ru file') { @options[:configru] = false }
      opts.on('-b', '--no-bundler',  'Do not create Gemfile for bundler') { @options[:bundler] = false }
      opts.on('-h', '--help', 'Display this information') { puts opts; exit }
      opts.on('-g', '--include-gem GEM', 'Require gem in gemfile') {|gem| @gems << gem}
      opts.on('-o','--orm ORM',[:activerecord,:dm,:none],'Generate model file for (dm (default), activerecord, none)') { |db| @options[:db] = db }
      opts.on('--[no-]git', 'Initialize git repo') {|git| options[:git] = git }
      opts.on('--views RENDERER',[:erb,:haml],"Use erb, or haml for views") {|view| @options[:view] = view }
      opts.on_tail("-h", "--help", "Display this information") { puts opts ; exit }
      begin
        opts.parse!
      rescue OptionParser::InvalidArgument
        opts.warn "Invalid Argument: #{$!}"
        exit 1
      end
      @app = ARGV[0]
      return opts
    end
    def init_dirs
      Dir.mkdir("./#{@app}")
      Dir.chdir("./#{@app}")
      Dir.mkdir("./tmp")
      Dir.mkdir("./views")
      Dir.mkdir("./public")
      Dir.mkdir('./config')
    end
    def write_files
      File.open("./config/database.yml",'w') do |file|
        file.write(@options[:db_yaml])
      end if @options.has_key?(:db_yaml)
      File.open("./models.rb",'w') do |file|
        file.write(@options[:model])
      end if @options.has_key? :model
      File.open("./Rakefile","w") do |file|
        file.write(@options[:rake_file])
      end if @options.has_key? :rake_file
      File.open("./Gemfile",'w') do |file|
        file.puts("source :rubygems")
        @gems.each {|gem| file.puts "gem '#{gem}'" unless gem.empty?}
      end if @options[:bundler]
      File.open("./app.rb",'w') do |file|
        file.write "
require 'rubygems'
require 'sinatra'
module Application
  class #{@app.capitalize} < Sinatra::Base
#{"\n    require './models.rb'\n" if @options[:dm] != :none }
    get '/' do
      'Now your classy'
    end
  end
end
"
        if ! @options[:configru] then
          file.puts "\n\Application::#{@app.capitalize}.run!"
        end
      end
      File.open("./config.ru","w") do |file|
        file.puts("require 'rubygems'")
        file.puts("require 'sinatra'")
        file.puts("\n\nrun Application::#{app.capitalize}")
      end if @options[:configru]
      File.open("./views/layout.#{@options[:view]}","w").close
      File.open("./views/index.#{@options[:view]}","w").close
     end
    def do_git
      if @options[:git] then
        `git init`
        `git add .`
        `git commit -m "Commited by #{__FILE__}"`
      end
    end
    def gen_files
      case @options[:db]
        when :activerecord then
          gems << 'activerecord'
          gems << 'mysql2'

          @options[:model] = <<EOS
require 'rubygems'
require 'active_record'
require 'yaml'
ActiveRecord::Base.establish_connection(File.open('config/database.yml'))

## Place your models below.
EOS

          @options[:db_yaml] = <<EOS
--
:adapter: mysql2
:host: localhost
:database: #{@app}
EOS
          @options[:rake_file] = <<EOS
require 'active_record'
require 'yaml'

ActiveRecord::Base.establish_connection(YAML.load_file('config/database.yml'))
namespace :db do
  desc 'Migrate dataabase'
  task :migrate do
   ActiveRecord::Base.logger = Logger.new(STDOUT)
   ActiveRecord::Migration.verbose = true
   ActiveRecord::Migrator.migrate("db/migrate")
end
EOS
          Dir.mkdir('./db'); Dir.mkdir('db/migrate')
          when :dm then
            gems << 'dm_core'
            gems << 'dm-mysql-adapter'
            @options[:model] = <<EOS
require 'rubygems'
require 'dm_core'
require 'dm-mysql-adapter'
DataMapper::Setup(:default, "mysql://localhost/#{@app}")

## Place your models below.
EOS
            @options[:rake_file] = <<EOS
namespace "db" do
  desc "Migrate the database"
  task :migrate, [:environment] do |t,args|
    args.with_defaults(:environment => ENV['RAILS_ENV'].nil? ? "production" : ENV['RAILS_ENV'])
    require './models.rb'
    DataMapper.auto_migrate!
  end
end
EOS
      end
    end
  end
  def self.run
    cli = CLI.new
    cli.run
    return cli
  end
end

GetClassy.run if $0 == __FILE__
