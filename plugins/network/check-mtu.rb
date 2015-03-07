#! /usr/bin/env ruby
#
#   check-mtu.rb
#
# DESCRIPTION:
#   Check MTU of a network interface
#   In many setups, MTUs are tuned. MTU mismatches cause issues. Having a check for MTU settings helps catch these mistakes.
#   Also, some instances in Amazon EC2 have default MTU size of 9,000 bytes. It is undesirable in some environments. This check can catch undesired setups.
#
# OUTPUT:
#   OK, Warning, Critical message
#
# PLATFORMS:
#   Linux
#
# DEPENDENCIES:
#   gem: sensu-plugin
#
# USAGE:
#   This will throw an error if interface eth0 does not have MTU of 1,500 bytes
#     check-mtu.rb --interface eth0 --mtu 1500
#   This will throw a warning if interface eth0 does not have MTU of 1,500 bytes
#     check-mtu.rb --interface eth0 --mtu 1500 --warn
#   This will throw an error if interface eth1 does not have MTU 9,000 bytes
#     check-mtu.rb --interface eth1 --mtu 9000
#   This will throw a waring if interface eth1 does not have MTU 9,000 bytes
#     check-mtu.rb --interface eth1 --mtu 9000 --warn
#
# NOTES:
#   Does it behave differently on specific platforms, specific use cases, etc
#
# LICENSE:
#   Robin <robin81@gmail.com>
#   Released under the same terms as Sensu (the MIT license); see LICENSE
#   for details.
#

require 'rubygems' if RUBY_VERSION < '1.9.0'
require 'sensu-plugin/check/cli'

class CheckMTU < Sensu::Plugin::Check::CLI
  option :interface,
         short: '-i INTERFACE',
         long: '--interface INTERFACE',
         description: 'Specify the interface',
         default: 'eth0'

  option :mtu,
         short: '-m MTU',
         long: '--mtu MTU',
         proc: proc(&:to_i),
         default: 1500

  option :warn,
         short: '-w',
         long: '--warn',
         boolean: true,
         default: false

  # rubocop:disable Metrics/AbcSize
  def run
    device = config[:interface]
    required_mtu = config[:mtu]

    mtu_file = "/sys/class/net/#{device}/mtu"

    error_handling = 'critical'
    error_handling = 'warning' if config[:warn]

    file_read_issue_error_message = "#{mtu_file} does not exist or is not readble"
    send(error_handling, file_read_issue_error_message) unless File.file?(mtu_file)

    mtu = IO.read(mtu_file).to_i
    mtu_mismatch_error_message = "Required MTU is #{required_mtu} and we found #{mtu}"
    send(error_handling, mtu_mismatch_error_message) unless mtu == required_mtu

    ok_message = "#{mtu} matches #{required_mtu}"
    ok ok_message
  end
end
