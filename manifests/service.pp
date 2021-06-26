define stdapp::service {
  $service_prefix = getvar("${name}::service_prefix")
  $service_timer = getvar("${name}::service_timer")
  $service_updown = std::service_ensure(getvar("${name}::ensure"), getvar("${name}::service_ensure"))

  service { "${name}":
    name => "${service_prefix}.service",
    * => $service_timer ? {
      undef => $service_updown,
      default => {
        ensure => stopped,
        enable => false,
      },
    },
  }

  if ($service_timer) {
    service { '${name}::timer':
      name => "${service_prefix}.timer",
      * => $service_updown,
    }
  }
}
define stdapp::service::install {
  $app_dir = getvar("${name}::app_dir")
  $service_prefix = getvar("${name}::service_prefix")
  $service_timer = getvar("${name}::service_timer")
  $service_override = getvar("${name}::service_override")

  $ensure = getvar("${name}::ensure")
  $app_settings = getvar("${name}::app_settings")

  $file_ensure = std::file_ensure($ensure)
  $dir_ensure = std::dir_ensure($ensure)

  file { "${name}::app_dir":
    path => $app_dir,
    ensure => $dir_ensure,
    force => true,
    require => File[stdapp::base_dir],
  }

  file { "${name}::dotenv":
    path => "${app_dir}/.env",
    ensure => $file_ensure,
    content => epp("${name}/dotenv", $app_settings),
    require => File["${name}::app_dir"],
  }

  file { "${name}::docker_compose":
    path => "${app_dir}/docker-compose.yml",
    ensure => $file_ensure,
    content => epp("${name}/docker-compose.yml", $app_settings),
    require => File["${name}::app_dir"],
  }

  file { "${name}::service":
    path => "/etc/default/${service_prefix}",
    ensure => $file_ensure ? { 'file' => 'link', default => 'absent' },
    target => $app_dir,
    require => [File["${name}::docker_compose"], File["${name}::dotenv"]],
    notify => Exec[systemd::reload],
    * => $stdapp::systemd_unit_perm,
  }

  if ($service_override) {
    file { "${name}::service::override::dir":
      path => "${stdapp::systemd_unit_dir}/${service_prefix}.d",
      ensure => $dir_ensure,
      force => true,
      * => $stdapp::systemd_unit_perm,
    }

    file { "${name}::service::override":
      path => "${stdapp::systemd_unit_dir}/${service_prefix}.d/override.conf",
      ensure => $file_ensure,
      content => epp($service_override, $app_settings),
      require => [File["${name}::service::override::dir"], File["${name}::service"]],
      * => $stdapp::systemd_unit_perm,
    }
  }

  if ($service_timer) {
    file { "${name}::service::timer":
      path => "${stdapp::systemd_unit_dir}/${service_prefix}.timer",
      content => epp($service_timer, $app_settings),
      ensure => $file_ensure,
      require => File["${name}::service"],
      notify => Exec[systemd::reload],
      * => $stdapp::systemd_unit_perm,
    }
  }
}
