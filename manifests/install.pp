# @summary
#
# Creates the Superset user and configures a Python virtual environment for installing Apache Superset and its dependent Python libraries 
#
# @api private
# 
class superset::install {

  group { $superset::user :
    ensure => present
  }

  user { $superset::user:
    ensure     => present,
    gid        => $superset::user,
    managehome => true
  }

  $superset_venv_dir = "${superset::install_dir}/apache-superset"

  # Add script for exporting the SUPERSET_CONFIG_PATH
  file { '/etc/profile.d/superset.sh':
    ensure  => file,
    owner   => $superset::user,
    group   => $superset::user,
    mode    => '0755',
    content => epp('superset/superset.sh.epp',{ superset_dir => $superset_venv_dir}),
  }

  # Create external fact for the install directory
  file { '/opt/puppetlabs/facter/facts.d/superset_installdir.txt':
    ensure  => file,
    owner   => $superset::user,
    group   => $superset::user,
    mode    => '0755',
    content => "superset_installdir=${$superset_venv_dir}",
  }

  $venv_python_ver = lookup('superset::python_version', String) ? {
    /\Apython([0-9])([0-9]+)/    => "${1}.${2}",
    /\Apython?([0-9])/           => "${1}",
    /\Arh-python([0-9])([0-9]+)/ => "${1}.${2}",
    /\Arh-python([0-9])/         => "${1}",
    default                      => lookup('superset::python_version', String),
  }

  # Create virtual environment for apache superset
  python::pyvenv { $superset_venv_dir:
    ensure     => present,
    version    => $venv_python_ver,
    owner      => $superset::user,
    group      => $superset::user,
    venv_dir   => $superset_venv_dir,
    systempkgs => false,
  }
  
  # Update pip before install
  python::pip { 'pip':
      ensure     => 'latest',
      pkgname    => 'pip',
      virtualenv => $superset_venv_dir,
      owner      => $superset::user,
      group      => $superset::user,
  }

  # Update wheel before install
  python::pip { 'wheel':
      ensure     => 'latest',
      pkgname    => 'wheel',
      virtualenv => $superset_venv_dir,
      owner      => $superset::user,
      group      => $superset::user,
  }

  # Install apache superset
  python::pip { 'apache-superset':
      ensure     => 'present',
      pkgname    => 'apache-superset',
      virtualenv => $superset_venv_dir,
      owner      => $superset::user,
      group      => $superset::user,
  }

  # Lock version of MarkupSafe due later versions breaking Superset https://github.com/apache/superset/issues/19150
  python::pip { 'MarkupSafe':
      ensure     => '2.0.1',
      pkgname    => 'MarkupSafe',
      virtualenv => $superset_venv_dir,
      owner      => $superset::user,
      group      => $superset::user,
  }

  # Install apache superset libraries for managing the webserver
  if $superset::manage_webserver {
    $webserver_venv_pip_pkg = ['gunicorn', 'gevent']
    $webserver_venv_pip_pkg.each | String $pkgname | {
      python::pip { $pkgname:
        ensure     => 'present',
        pkgname    => $pkgname,
        virtualenv => $superset_venv_dir,
        owner      => $superset::user,
        group      => $superset::user,
      }
    }
  }

  # Install required database drivers
  $superset::db_drivers.each | String $pkgname | {
    python::pip { $pkgname:
      ensure     => 'present',
      pkgname    => $pkgname,
      virtualenv => $superset_venv_dir,
      owner      => $superset::user,
      group      => $superset::user,
    }
  }
}
