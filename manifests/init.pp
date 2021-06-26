class stdapp {
  include std

  $base_dir = '/app'

  $systemd_unit_perm = {
    mode => '644',
    owner => 'root',
    group => 'root',
  }

  file { stdapp::base_dir:
    path => $base_dir,
    ensure => directory,
    mode => '775',
    owner => 'root',
    group => 'wheel',
  }
}
