# Class: puppet::params
#
# This class installs and configures parameters for Puppet
#
# Parameters:
#
# Actions:
#
# Requires:
#
# Sample Usage:
#
class puppet::params {

  $puppet_server                    = 'puppet'
  $modulepath                       = '/etc/puppet/modules'
  $puppet_user                      = 'puppet'
  $puppet_group                     = 'puppet'
  $storeconfigs_dbserver            = $::fqdn
  $storeconfigs_dbport              = '8081'
  $certname                         = $::fqdn
  $confdir                          = '/etc/puppet'
  $manifest                         = '/etc/puppet/manifests/site.pp'
  $hiera_config                     = '/etc/puppet/hiera.yaml'
  $puppet_docroot                   = '/etc/puppet/rack/public/'
  $puppet_passenger_port            = '8140'
  $puppet_server_port               = '8140'
  $puppet_agent_enabled             = true
  $apache_serveradmin               = 'root'
  $parser                           = 'current'
  $puppetdb_strict_validation       = true
  $environments                     = 'config'
  $digest_algorithm                 = 'md5'
  $puppet_run_interval              = 30
  $classfile                        = '$statedir/classes.txt'
  $rundir                           = '/var/run/puppet'
  $puppet_passenger_ssl_protocol    = 'TLSv1.2'
  $puppet_passenger_ssl_cipher      = 'AES256+EECDH:AES256+EDH'

  # Only used when environments == directory
  $environmentpath                  = "${confdir}/environments"

  if versioncmp($::puppetversion, "4.0.0") >= 0 {
    $puppet_conf        = '/etc/puppetlabs/puppet/puppet.conf'
    $puppet_run_command = '/opt/puppetlabs/bin/puppet agent --no-daemonize --onetime --logdest syslog > /dev/null 2>&1'
    $puppet_vardir      = '/opt/puppetlabs/server/data/puppetserver'
    $puppet_ssldir      = '/etc/puppetlabs/puppet/ssl'
  } else {
    $puppet_conf        = '/etc/puppet/puppet.conf'
    $puppet_run_command = '/usr/bin/puppet agent --no-daemonize --onetime --logdest syslog > /dev/null 2>&1'
    $puppet_vardir      = '/var/lib/puppet'
    $puppet_ssldir      = '/var/lib/puppet/ssl'
  }

  case $::osfamily {
    'RedHat': {
      $puppet_master_package        = 'puppet-server'
      $puppet_master_service        = 'puppetmaster'
      $puppet_agent_service         = 'puppet'
      $puppet_agent_package         = 'puppet'
      $package_provider                 = undef # falls back to system default
      $puppet_defaults              = '/etc/sysconfig/puppet'
      $passenger_package            = 'mod_passenger'
      $rack_package                 = 'rubygem-rack'
      $ruby_dev                     = 'ruby-devel'
      $puppet_facter_package        = nil
      $ruby_diff_lcs                = 'rubygem-diff-lcs'
    }
    'Suse': {
      $puppet_master_package        = 'puppet-server'
      $puppet_master_service        = 'puppetmasterd'
      $puppet_agent_service         = 'puppet'
      $puppet_agent_package         = 'puppet'
      $package_provider                 = undef # falls back to system default
      $passenger_package            = 'rubygem-passenger-apache2'
      $rack_package                 = 'rubygem-rack'
      $puppet_facter_package        = nil
      $ruby_diff_lcs                = 'rubygem-diff-lcs'
    }
    'Debian': {
      $puppet_master_package        = 'puppetmaster'
      $puppet_master_service        = 'puppetmaster'
      $puppet_agent_service         = 'puppet'
      $puppet_agent_package         = 'puppet'
      $package_provider                 = undef # falls back to system default
      $puppet_defaults              = '/etc/default/puppet'
      $passenger_package            = 'libapache2-mod-passenger'
      $rack_package                 = 'librack-ruby'
      $ruby_dev                     = 'ruby-dev'
      $puppet_facter_package        = nil
      $ruby_diff_lcs                = 'ruby-diff-lcs'
    }
    'FreeBSD': {
      $puppet_agent_service         = 'puppet'
      $puppet_agent_package         = 'sysutils/puppet'
      $package_provider                 = undef # falls back to system default
      $puppet_conf                  = '/usr/local/etc/puppet/puppet.conf'
      $puppet_facter_package        = nil
    }
    'Darwin': {
      $puppet_agent_service         = 'com.puppetlabs.puppet'
      $puppet_agent_package         = 'puppet-3.8.6.dmg'
      $puppet_facter_package        = 'facter-2.4.6.dmg'
      $package_provider             = 'pkgdmg'
      $puppet_conf                  = '/etc/puppet/puppet.conf'
      $puppet_vardir                = '/var/lib/puppet'
      $puppet_ssldir                = '/var/lib/puppet/ssl'
    }
    default: {
      err('The Puppet module does not support your os')
    }
  }
}
