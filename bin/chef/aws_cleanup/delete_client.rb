#!/usr/bin/env ruby
# Author: Jacob Royal
# Created: 06/10/2016
# Last Update: 06/23/2016
# Overview 
# Takes a list of all chef nodes that use AWS instance ids as their names and compares it to a list of all running AWS instances 
# in a given account. If there are instances in chef that are not running in AWS, it will delete those chef clients/nodes. 
# Useful for some one off cleanup, but not a good solution as a long term de-registration/cleanup plan. Tailor to environment needs.

#TODO: get rid of the manual steps

=begin
** The following commands must be run within the same directory as this script **
1. Switch to the appropriate knife block
2. Generate a chef_nodes.txt file with a command similare to the following (the i-* ensures only nodes that are in an ASG are searched for)
  `knife search node 'name:i-*' -i > chef_nodes.txt`
3. Generate a aws_instances.txt file using a command like the following (gets active aws instances)
  `AWS_ACCESS_KEY_ID=$<ENV>_AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY=$<ENV>_AWS_SECRET_ACCESS_KEY aws ec2 describe-instances | jq -r ".Reservations[].Instances[] | select(.State.Name == \"running\") | .InstanceId" > aws_instances.txt`
4. Run this script
=end

require 'json'
require 'pp'

KNIFE = '/opt/chefdk/bin/knife'

def parse_raw_chef_nodes
  file = File.read('./chef_nodes.txt')
  nodes = file.split("\n")
  nodes
end

def parse_aws_instances
  file = File.read('./aws_instances.txt')
  instance_arr = file.split("\n")
  instance_arr
end

def remove_active_instances(chef_nodes, aws_instances)
  count = 0
  active_clients = chef_nodes & aws_instances
  dead_clients = chef_nodes
  
  active_clients.each do |active|
    dead_clients = dead_clients - [active]
  end

  dead_clients
end

def delete_clients(clients=[])
  clients.each do |client|
    puts "Deleting: #{client}"
    delete = `#{KNIFE} node delete -y #{client} && #{KNIFE} client delete -y #{client}`
    puts delete
    sleep(3)
  end
end


puts 'MAKE SURE YOU HAVE GONE THROUGH THE LIST OF NODES AND MAKE SURE ONLY STALE NODES IN THE LIST'
block = `#{KNIFE} block show`
puts "\n active knife block = #{block}\n"

puts 'are you sure you want to proceed?(y/n)'
confirm = gets.chomp

if confirm == 'y'
  chef_nodes = parse_raw_chef_nodes
  aws_instances = parse_aws_instances

  dead_clients = remove_active_instances(chef_nodes, aws_instances)
  
  puts "\n#{dead_clients.length} marked for deletion. Continue? (y/n)"
  confirmation = gets.chomp

  if confirmation == 'y'
    delete_clients(dead_clients)
  else
    puts 'deletion was not confirmed, exiting'
  end
  exit 0
else
  puts 'exiting now'
  exit 1
end


