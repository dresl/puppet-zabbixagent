# Class: zabbixagent
#
# This module manages the zabbix agent on a monitored machine.
#
# Parameters: none
#
# Actions:
#
# Requires: see Modulefile
#
# Sample Usage:
#
class zabbixagent(
  $servers = '',
  $hostname = '',
  $version = '',
  $active_servers = '',
) {
  $servers_real = $servers ? {
    ''      => 'localhost',
    default => $servers,
  }

  $active_servers_real = $active_servers ? {
    ''      => 'localhost',
    default => $active_servers,
  }

  $hostname_real = $hostname ? {
    ''      => $::fqdn,
    default => $hostname,
  }

  $version_real = $version ? {
    ''      => '1',
    default => $version,
  }

  #
  # check os and version
  #
  $os_release = $::operatingsystemrelease
    
  $msg_untestedrelease = "Untested version ($os_release) of operating system..."
    
  $msg_testedrelease = "Tested on this version ($os_release) of operating system... OK"
    
  $msg_untestedos = "Untested operating system..."
  
  if $::operatingsystem == "centos" {
    
    if( $os_release >= 5 and $os_release < 5.9) {
	notice "Tested on a newer version of operating system than this ($os_release). Please update your OS."
    }
    elsif( $os_release >= 5 and $os_release < 6) {
	notice $msg_testedrelease
    }
    elsif( $os_release >= 6 and $os_release < 6.4) {
        notice "Tested on a newer version of operating system than this ($os_release). Please update your OS."
    }
    elsif( $os_release == 6.4) {
        notice $msg_testedrelease
    }
    else {
         notice $msg_untestedrelease
    }
  }
  elsif($::operatingsystem == "ubuntu") {
  
         if( $os_release == 12.04 ){
             notice $msg_testedrelease
         }
         else {
            notice $msg_untestedrelease
         }
  
  }
  else{
     notice $msg_untestedos
  }

  #
  #  install and resolve package(s)
  #
  
  case $::operatingsystem {
    centos: {
      include epel

      if $version_real == 2 {

        $package = "zabbix20-agent"

        package {"zabbix-agent" :
           ensure  => absent
        }
        package {"zabbix" :
           ensure  => absent
        }

        package {"$package" :
          ensure  => installed,
          require => Yumrepo["epel"]
        } 
       }
       elsif $version_real == 1 {

        $package = "zabbix-agent"

        package {"zabbix20-agent" :
           ensure  => absent
        }
        package {"zabbix20" :
           ensure  => absent
        }

        package {"$package" :
          ensure  => installed,
          require => Yumrepo["epel"]
        } 
     
       }
       else {

         notice "Unsupported version  ${version}, choose 1 or 2."
       }

    }

    debian, ubuntu: {

      $package = "zabbix-agent"

      if $version_real == 2 {

	if( $os_release == 12.04 ){
	
            #download a install repo file

            $file = "http://repo.zabbix.com/zabbix/2.0/ubuntu/pool/main/z/zabbix-release/zabbix-release_2.0-1precise_all.deb"
            $dfile = "/tmp/zabbix-release_2.0-1precise_all.deb"

            exec { "download repo file":
              command => "wget '$file' -O $dfile",
              path => "/usr/bin",
            }

            package {"zabbix_repo":
                provider => dpkg,
                ensure => installed,
                source => "$dfile",
                subscribe => Exec["download repo file"],
            }

            file { "$dfile" :
                ensure => absent,
                subscribe => Package["zabbix_repo"],
            }

            exec { 'apt-get update':
               command => '/usr/bin/apt-get update',
               subscribe => Package["zabbix_repo"],
            }

	    package {$package :
		ensure => '1:2.0.7-1+precise',
        	require => Exec['apt-get update']
    	    }
    	    
	}
	else{
	    notice "I can't install version ${version} of zabbix-agent on this OS Release ($os_release)."
	    notice "exiting..."             
	}     
	                         
      }
      elsif $version_real == 1 {

        package {$package :
    	    ensure  => installed
        }
    
      }
      else {

         notice "Unsupported version  ${version}, choose 1 or 2."
      }
  
     }
    }

  #
  #  modify configuration files
  #
  
  case $::operatingsystem {
  
    centos: {
    
      ini_setting { 'servers setting':
        ensure  => present,
        path    => '/etc/zabbix/zabbix_agentd.conf',
        section => '',
        setting => 'Server',
        value   => join(flatten([$servers_real]), ','),
        subscribe => Package[$package],
      }
    
      if $version_real == 2 {

        ini_setting { 'active servers setting':
         ensure  => present,
         path    => '/etc/zabbix/zabbix_agentd.conf',
         section => '',
         setting => 'ServerActive',
         value   => join(flatten([$active_servers_real]), ','),
         subscribe => Package[$package],
        }

      }

      ini_setting { 'hostname setting':
        ensure  => present,
        path    => '/etc/zabbix/zabbix_agentd.conf',
        section => '',
        setting => 'Hostname',
        value   => $hostname_real,
        subscribe => Ini_setting['servers setting'],
      }
    
      ini_setting { 'Include setting':
        ensure  => present,
        path    => '/etc/zabbix/zabbix_agentd.conf',
        section => '',
        setting => 'Include',
        value   => '/etc/zabbix/zabbix_agentd/',
        subscribe => Ini_setting['hostname setting'],
      }

      file { '/etc/zabbix/zabbix_agentd':
        ensure  => directory,
        subscribe => Ini_setting['Include setting'],
      }

      service {'zabbix-agent' :
        ensure  => running,
        enable  => true,
        subscribe => File['/etc/zabbix/zabbix_agentd'],    
      }

    
    }
    
    debian, ubuntu: {

      ini_setting { 'servers setting':
        ensure  => present,
        path    => '/etc/zabbix/zabbix_agentd.conf',
        section => '',
        setting => 'Server',
        value   => join(flatten([$servers_real]), ','),
        subscribe => Package[$package],
      }

      if $version_real == 2 {

        ini_setting { 'active servers setting':
         ensure  => present,
         path    => '/etc/zabbix/zabbix_agentd.conf',
         section => '',
         setting => 'ServerActive',
         value   => join(flatten([$active_servers_real]), ','),
         subscribe => Ini_setting['servers setting'],
        }

      }

      ini_setting { 'hostname setting':
        ensure  => present,
        path    => '/etc/zabbix/zabbix_agentd.conf',
        section => '',
        setting => 'Hostname',
        value   => $hostname_real,
        subscribe => Ini_setting['servers setting'],
      }

      ini_setting { 'Include setting':
        ensure  => present,
        path    => '/etc/zabbix/zabbix_agentd.conf',
        section => '',
        setting => 'Include',
        value   => '/etc/zabbix/zabbix_agentd/',
        subscribe => Ini_setting['hostname setting'],
      }

      file { '/etc/zabbix/zabbix_agentd':
        ensure  => directory,
        subscribe => Ini_setting['Include setting'],
      }

      service {'zabbix-agent' :
        ensure  => running,
        enable  => true,
        require => Package[$package],
        subscribe => File['/etc/zabbix/zabbix_agentd'],
      }


    }
    windows: {
      $confdir = 'C:/ProgramData/Zabbix'
      $homedir = 'C:/Program Files/Zabbix/'

      file { $confdir: ensure => directory }
      file { "${confdir}/zabbix_agentd.conf":
        ensure  => present,
        mode    => '0770',
      }

      ini_setting { 'servers setting':
        ensure  => present,
        path    => "${confdir}/zabbix_agentd.conf",
        section => '',
        setting => 'Server',
        value   => join(flatten([$servers_real]), ','),
        require => File["${confdir}/zabbix_agentd.conf"],
      }

        ini_setting { 'active servers setting':
         ensure  => present,
         path    => "${confdir}/zabbix_agentd.conf",
         section => '',
         setting => 'ServerActive',
         value   => join(flatten([$active_servers_real]), ','),
         require => File["${confdir}/zabbix_agentd.conf"],
        }

      ini_setting { 'hostname setting':
        ensure  => present,
        path    => "${confdir}/zabbix_agentd.conf",
        section => '',
        setting => 'Hostname',
        value   => $hostname_real,
        require => File["${confdir}/zabbix_agentd.conf"],
      }

      file { $homedir:
        ensure  => directory,
        source  => 'puppet:///modules/zabbixagent/win64',
        recurse => true,
        mode    => '0770',
      }

      exec { 'install Zabbix Agent':
        path    => $::path,
        cwd     => $homedir,
        command => "\"${homedir}/zabbix_agentd.exe\" --config ${confdir}/zabbix_agentd.conf --install",
        require => [File[$homedir], File["${confdir}/zabbix_agentd.conf"]],
        unless  => 'sc query "Zabbix Agent"'
      }

      service { 'Zabbix Agent':
        ensure  => running,
        require => Exec['install Zabbix Agent'],
      }
    }
    default: { notice "Unsupported operatingsystem  ${::operatingsystem}" }
  }
}
