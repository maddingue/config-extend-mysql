use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Config::Extend::MySQL',
    license             => 'perl',
    dist_author         => 'Sebastien Aperghis-Tramoni <sebastien@aperghis.net>',
    dist_version_from   => 'lib/Config/Extend/MySQL.pm',
    requires => {
        'Carp'                  => '0',
        'Config::Tiny'          => '0',
        'File::Basename'        => '0',
        'File::Read'            => '0',
        'File::Spec::Functions' => '0',
        'UNIVERSAL::require'    => '0',
    },
    build_requires => {
        'Test::More'        => 0,
    },
    add_to_cleanup      => [ 'Config-Extend-MySQL-*' ],
);

$builder->create_build_script();
