# frozen_string_literal: true

require 'puppet/util/nc_classifier'
require 'puppet/util/nc_codemanager'
require 'puppet/util/nc_server'
require 'puppet/util/cli-tree'
require 'puppet/util/cli-table'

class Puppet::Application::Visual < Puppet::Application
  def summary
    "Visualize information from a PE install"
  end

  def help
    <<~HELP
puppet-visual(8) -- #{summary}
========

SYNOPSIS
--------
Visualize information from a configured Puppet Enterprise installation

USAGE
-----
puppet visual <action> [-h|--help]


OPTIONS
-------

* --help:
  Print this help message.

ACTIONS
-------

* node_groups:
  Query the classification endpoint and print out a tree view of only node groups

* environment_groups:
  Query the classification endpoint and print out a tree view of only environment groups

* all_groups:
  Query the classification endpoint and print out a tree view of all groups

* deploy_status:
  Query the deploy-status endpoint and print out pretty JSON

    HELP
  end

  def main
    # call action
    send(@command_line.args.shift)
  end

  option("--auth_token [TOKEN]") do |v|
    options[:auth_token] = v
  end

  option("--env [ENV]") do |v|
    options[:env] = v
  end

  def environment_groups
    classifier = Puppet::Util::Nc_classifier.new(options: options)
    my_json = classifier.get('/classifier-api/v1/groups')
    print_classifier_groups(my_json,'env_gp')
  end

  def node_groups
    classifier = Puppet::Util::Nc_classifier.new(options: options)
    my_json = classifier.get('/classifier-api/v1/groups')
    print_classifier_groups(my_json,'n_gp')
  end

  def all_groups
    classifier = Puppet::Util::Nc_classifier.new(options: options)
    my_json = classifier.get('/classifier-api/v1/groups')
    print_classifier_groups(my_json)
  end

  def deploy_status
    codemanager = Puppet::Util::Nc_codemanager.new(options: options)
    my_json = codemanager.get('/code-manager/v1/deploys/status')
    puts JSON.pretty_generate(my_json)
  end

  def print_modules(json_data)
    clean_keys = json_data['modules'].map{|hash| hash.transform_keys(&:to_sym) }
    clean_vals = clean_keys.map do |hash|
      hash.transform_values do |value|
        value.nil? ? 'N/A' : value
      end
    end

    table = Puppet::Util::Clitable.new({name: 'Module Name', version: 'Version'},clean_vals)
    table.print
  end

  def environment_modules
    server = Puppet::Util::Nc_server.new(options: options)
    req_params = options.key?(:env) ? {'environment' => options[:env]} : nil
    my_json = server.get('/puppet/v3/environment_modules', req_params)
    if my_json.is_a?(Hash)
      # returns a hash when env specified
      print_modules(my_json)
    elsif my_json.is_a?(Array)
      # returns an array when no env specified
      my_json.each do |env_mods|
        puts env_mods['name']
        print_modules(env_mods)
      end
    end
#    puts JSON.pretty_generate(my_json)
  end

  def environment_classes
    server = Puppet::Util::Nc_server.new(options: options)
    req_params = options.key?(:env) ? {'environment' => options[:env]} : nil
    my_json = server.get('/puppet/v3/environment_classes', req_params)
    puts JSON.pretty_generate(my_json)
  end

  def print_classifier_groups(json_data, filter = nil)
    groups = {}

    # json looking for env groups
    json_data.each do |group|

      case filter
      when 'env_gp'
        next unless group['environment_trumps']
      when 'n_gp'
        next if group['environment_trumps']
      end

      groups[group['id']] = {
        'environment_trumps' => group['environment_trumps'],
        'name'               => group['name'],
        'parent'             => group['parent'],
        'environment'        => group['environment']
      }
    end

    # make sure we have the parent groups
    missing = {}
    groups.each do |_id, data|
      next if groups.key?(data['parent'])

      missing[data['parent']] = {
        'environment_trumps' => json_data[data['parent'].to_i]['environment_trumps'],
        'name'               => json_data[data['parent'].to_i]['name'],
        'parent'             => json_data[data['parent'].to_i]['parent'],
        'environment'        => json_data[data['parent'].to_i]['environment']
      }
    end

    groups.merge!(missing)

    # Find the root of the tree
    top = groups.select { |id, data| id == data['parent'] }.keys.first

    # Used to store children and id's
    tree = Hash.new { |h, k| h[k] = { :id => nil, :name => nil, :children => [ ] } }

    # Find all the children and keep track
    groups.each do |id, data|
      eg = groups[id]['environment_trumps']
      parent = data['parent'] unless id == data['parent']
      tree[id][:id] = id
      tree[id][:name] = eg ? "#{data['name']} (Env: #{data['environment']})" : "#{data['name']}"
      tree[parent][:children].push(tree[id])
    end

    # Print out
    Puppet::Util::TreeNode.from_h(tree[top]).print

  end
end
