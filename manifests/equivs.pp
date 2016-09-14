# note this only supports jdk and server-jre for now
define jdk_oracle::equivs (
  $package         = 'jdk',
  $version         = '8',
) {
  $provides_base = [
    'default-jre',
    'default-jre-headless',
    'java-compiler',
    'java-jdk',
    'java-runtime',
    'java-runtime-headless',
    'java-sdk',
    'java-virtual-machine',
    'java2-jdk',
    'java2-runtime',
    'java2-runtime-headless',
    'java2-sdk',
    'java5-jdk',
    'java5-runtime',
    'java5-runtime-headless',
    'java5-sdk',
  ];
  $provides_6 = $provides_base + [
    'icedtea-6-plugin',
    'java6-jdk',
    'java6-runtime',
    'java6-runtime-headless',
    'java6-sdk',
    'openjdk-6-jre',
    'openjdk-6-jre-headless',
  ]
  $provides_7 = $provides_6 + [
    'icedtea-7-plugin',
    'java7-jdk',
    'java7-runtime',
    'java7-runtime-headless',
    'java7-sdk',
    'openjdk-7-jdk',
    'openjdk-7-jre',
    'openjdk-7-jre-headless',
    'oracle-java7-bin',
    'oracle-java7-fonts',
    'oracle-java7-jdk',
    'oracle-java7-jre',
    'oracle-java7-plugin',
  ]
  $provides_8 = $provides_7 + [
    'java8-jdk',
    'java8-runtime',
    'java8-runtime-headless',
    'java8-sdk',
    'oracle-java8-bin',
    'oracle-java8-fonts',
    'oracle-java8-jdk',
    'oracle-java8-jre',
    'oracle-java8-plugin'
  ]

  $replaces_base = []
  $replaces_6 = $replaces_base + [
    'icedtea-6-plugin',
    'openjdk-6-jre',
    'openjdk-6-jre-headless',
  ]
  $replaces_7 = $replaces_6 + [
    'icedtea-7-plugin',
    'openjdk-7-jdk',
    'openjdk-7-jre',
    'openjdk-7-jre-headless',
    'oracle-java7-bin',
    'oracle-java7-fonts',
    'oracle-java7-jdk',
    'oracle-java7-jre',
    'oracle-java7-plugin',
    'oracle-jdk7-installer'
  ]
  $replaces_8 = $replaces_7 + []


  case $version {
    '8': {
      $provides = $provides_8
      $replaces = $replaces_8
    }
    '7': {
      $provides = $provides_7
      $replaces = $replaces_7
    }
    '6': {
      $provides = $provides_6
      $replaces = $replaces_6
    }
    default: {
      fail("Unsupported version: ${version}.  Implement me?")
    }
  }

  if ! defined(Package["equivs"]) {
    package { 'equivs':
      ensure    => present,
      require   => Exec["extract_${package}_${version}"]
    }
  }

  $package_name = "oracle-jdk-dummy"
  $control_file = '/tmp/oracle-java-dummy.control'
  file { "$control_file":
    ensure   => file,
    content  => template("jdk_oracle/oracle-java-dummy.control.erb"),
    require  => Package["equivs"],
  }

  # cannot use unless as package resource does not have unless, and there's no easy of ensuring the debian file exists
  exec { "/usr/bin/equivs-build $control_file":
    cwd     => '/tmp',
    require => File["$control_file"],
    # unless  => '/usr/bin/dpkg-query -W --showformat "${Status} ${Package} ${Version}\n" oracle-jdk-dummy'
  }

  $deb_file = "/tmp/oracle-jdk-dummy_1.${version}_all.deb"
  package { "$package_name":
    provider => dpkg,
    ensure   => present,
    source   => $deb_file,
    require  => Exec["/usr/bin/equivs-build $control_file"]
    # unless   => "test ! -f $deb_file"
  }

}
