# Class: puppet::passenger
#
# This class installs and configures the puppetdb terminus pacakge
#
# Parameters:
#   ['generate_ssl_certs']       - Generate ssl certs (false to disable)
#   ['puppet_passenger_port']    - The port for the virtual host
#   ['puppet_docroot']           - Apache documnet root
#   ['apache_serveradmin']       - The apache server admin
#   ['puppet_conf']              - The puppet config dir
#   ['puppet_ssldir']            - The pupet ssl dir
#   ['certname']                 - The puppet certname
#   [conf_dir]                   - The configuration directory of the puppet install
#
# Actions:
# - Configures apache and passenger for puppet master use.
#
# Requires:
# - Inifile
# - Class['puppet::params']
# - Class['apache']
#
# Sample Usage:
#   class { 'puppet::passenger':
#           puppet_passenger_port  => 8140,
#           puppet_docroot         => '/etc/puppet/docroot',
#           apache_serveradmin     => 'wibble',
#           puppet_conf            => '/etc/puppet/puppet.conf',
#           puppet_ssldir          => '/var/lib/puppet/ssl',
#           certname               => 'puppet.example.com',
#           conf_dir               => '/etc/puppet',
#   }
#
class puppet::passenger(
  $puppet_passenger_port,
  $puppet_passenger_ssl_protocol,
  $puppet_passenger_ssl_cipher,
  $puppet_docroot,
  $apache_serveradmin,
  $puppet_conf,
  $puppet_ssldir,
  $certname,
  $conf_dir,
  $dns_alt_names,
  $passenger_root = undef,
  $generate_ssl_certs = true,
  $puppet_passenger_tempdir = false,
  $config_addon = '',
  $passenger_max_pool_size = 6,
  $passenger_high_performance = 'off',
  $passenger_max_requests = 0,
  $passenger_stat_throttle_rate = 10,
  $passenger_disable_mod_status = true,
){

  class { 'apache':
    default_mods        => false,
    default_confd_files => false,
    default_vhost       => false,
    server_tokens       => 'Prod',
    server_signature    => 'Off',
    trace_enable        => 'Off',
  }

  if $passenger_disable_mod_status {
    apache::mod { 'status': package_ensure => 'absent' }
  }

  include puppet::params
  class { 'apache::mod::passenger':
    passenger_max_pool_size      => $passenger_max_pool_size,
    passenger_high_performance   => $passenger_high_performance,
    passenger_max_requests       => $passenger_max_requests,
    passenger_stat_throttle_rate => $passenger_stat_throttle_rate,
    passenger_root               => $passenger_root,
  }

  class { 'apache::mod::ssl':
    ssl_protocol => [$puppet_passenger_ssl_protocol],
    ssl_cipher   => $puppet_passenger_ssl_cipher,
  }

  if $::osfamily == 'redhat' {
    file { '/var/lib/puppet/reports':
      ensure => directory,
      owner  => $::puppet::params::puppet_user,
      group  => $::puppet::params::puppet_group,
    }
  }

  if str2bool($generate_ssl_certs) == true {
    file{"${puppet_ssldir}/ca":
      ensure => directory,
      owner  => $::puppet::params::puppet_user,
      group  => $::puppet::params::puppet_group,
      before => Exec['Certificate_Check'],
    }

    file{"${puppet_ssldir}/ca/requests":
      ensure => directory,
      owner  => $::puppet::params::puppet_user,
      group  => $::puppet::params::puppet_group,
      before => Exec['Certificate_Check'],
    }
    # first we need to generate the cert
    # Clean the installed certs out ifrst
    $crt_clean_cmd  = "puppet cert clean ${certname}"
    # I would have preferred to use puppet cert generate, but it does not
    # return the corret exit code on some versions of puppet
    $crt_gen_cmd   = "puppet certificate --ca-location=local --dns_alt_names=${dns_alt_names} generate ${certname}"
    # I am using the sign command here b/c AFAICT, the sign command for certificate
    # does not work
    $crt_sign_cmd  = "puppet cert sign --allow-dns-alt-names ${certname}"
    # find is required to move the cert into the certs directory which is
    # where it needs to be for puppetdb to find it
    $cert_find_cmd = "puppet certificate --ca-location=local find ${certname}"

    exec { 'Certificate_Check':
      command   => "${crt_clean_cmd} ; ${crt_gen_cmd} && ${crt_sign_cmd} && ${cert_find_cmd}",
      unless    => "/bin/ls ${puppet_ssldir}/certs/${certname}.pem",
      path      => '/usr/bin:/usr/local/bin:/opt/puppetlabs/bin/',
      logoutput => on_failure,
      require   => File[$puppet_conf]
    }
  }

  file { $puppet_docroot:
    ensure => directory,
    owner  => $::puppet::params::puppet_user,
    group  => $::puppet::params::puppet_group,
    mode   => '0755',
  }

  apache::vhost { "puppet-${certname}":
    port                 => $puppet_passenger_port,
    priority             => '40',
    docroot              => $puppet_docroot,
    serveradmin          => $apache_serveradmin,
    servername           => $certname,
    ssl                  => true,
    ssl_cert             => "${puppet_ssldir}/certs/${certname}.pem",
    ssl_key              => "${puppet_ssldir}/private_keys/${certname}.pem",
    ssl_chain            => "${puppet_ssldir}/ca/ca_crt.pem",
    ssl_ca               => "${puppet_ssldir}/ca/ca_crt.pem",
    ssl_crl              => "${puppet_ssldir}/ca/ca_crl.pem",
    ssl_protocol         => $puppet_passenger_ssl_protocol,
    ssl_cipher           => $puppet_passenger_ssl_cipher,
    ssl_honorcipherorder => 'On',
    ssl_verify_client    => 'optional',
    ssl_verify_depth     => '1',
    ssl_options          => ['+StdEnvVars', '+ExportCertData'],
    rack_base_uris       => '/',
    directories          => [
      {
        path => $puppet_docroot,
      },
      {
        path    => '/etc/puppet/rack',
        options => 'None',
      },
    ],
    require              => [ File['/etc/puppet/rack/config.ru'], File[$puppet_conf] ],
  }

  #Hack to add extra passenger configurations for puppetmaster
  file { 'puppet_passenger.conf':
    ensure  => file,
    path    => "${apache::mod_dir}/puppet_passenger.conf",
    content => template('puppet/puppet_passenger.conf.erb'),
    notify  => Service['httpd'],
  }

  file { '/etc/puppet/rack':
    ensure => directory,
    owner  => $::puppet::params::puppet_user,
    group  => $::puppet::params::puppet_group,
    mode   => '0755',
  }

  file { '/etc/puppet/rack/config.ru':
    ensure  => present,
    owner   => $::puppet::params::puppet_user,
    group   => $::puppet::params::puppet_group,
    content => template('puppet/config.erb'),
    mode    => '0644',
  }

  ini_setting {'puppetmastersslclient':
    ensure  => present,
    section => 'master',
    setting => 'ssl_client_header',
    path    => $puppet_conf,
    value   => 'SSL_CLIENT_S_DN',
    require => File[$puppet_conf],
  }

  ini_setting {'puppetmastersslclientverify':
    ensure  => present,
    section => 'master',
    setting => 'ssl_client_verify_header',
    path    => $puppet_conf,
    value   => 'SSL_CLIENT_VERIFY',
    require => File[$puppet_conf],
  }
}
