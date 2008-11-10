#!perl -T
use strict;
use File::Spec::Functions;
use Test::More;


my $module   = "Config::Extend::MySQL";
my @methods  = qw(new);
my @backends = qw(
    Config::IniFiles  Config::INI::Reader  Config::Tiny
);
# not yet working:  Config::Format::Ini  Config::Simple

plan skip_all => "UNIVERSAL::require is required"
    unless eval "use UNIVERSAL::require; 1";

my @cases = (
#    {
#        file   => catfile(qw(t files 01empty.cnf)),
#        struct => [],
#    },
#    {
#        file   => catfile(qw(t files 02empty_comments.cnf)),
#        struct => [],
#    },
#    {
#        file   => catfile(qw(t files 03single_param_with_value.cnf)),
#        struct => [
#            [ section => debug => "yes" ],
#        ],
#    },
#    {
#        file   => catfile(qw(t files 04single_param_without_value.cnf)),
#        struct => [
#            [ section => debug => "yes" ],
#        ],
#    },
    {
        file   => catfile(qw(t files 05section.cnf)),
        struct => [],
    },
    {
        file   => catfile(qw(t files 06section_param_with_value.cnf)),
        struct => [
            [ main => debug => "yes" ],
        ],
    },
    {
        file   => catfile(qw(t files 07section_param_without_value.cnf)),
        struct => [
            [ main => debug => "yes" ],
        ],
    },
    {
        file   => catfile(qw(t files 08section_include.cnf)),
        struct => [
            [ main => debug => "no" ],
        ],
    },
#    {
#        file   => catfile(qw(t files 09section_param_before_include.cnf)),
#        struct => [
#            [ main => debug => "no" ],
#        ],
#    },
#    {
#        file   => catfile(qw(t files 10section_param_after_include.cnf)),
#        struct => [
#            [ main => debug => "yes" ],
#        ],
#    },
    {
        file   => catfile(qw(t files 11section_param_includedir.cnf)),
        struct => [
            [ mysqladmin => debug => "no" ],
            [ mysqladmin => user  => "root" ],
            [ mysqladmin => password => "5ekr3t" ],
            [ mysqld => old_passwords => "false" ],
        ],
    },
    {
        file   => catfile(qw(t files real_world_sample_1.cnf)),
        struct => [
            [ mysqld =>  old_passwords  => "true" ],
            [ mysqld =>  user           => "mysql" ],
            [ mysqld => "pid-file"      => "/var/run/mysqld/mysqld.pid" ],
            [ mysqld => "skip-external-locking" => "yes" ],
            [ mysqld =>  thread_cache_size  => 300 ],
            [ mysqld =>  max_connections    => 1500 ],
            [ mysqld =>  wait_timeout       => 28800 ],
        ],
    },
    {
        file   => catfile(qw(t files real_world_sample_2.cnf)),
        struct => [
            [ mysqld =>  user           => "mysql" ],
            [ mysqld => "pid-file"      => "/var/run/mysqld/mysqld.pid" ],
            [ mysqld => "skip-external-locking" => "yes" ],
            [ mysqld =>  thread_cache_size  => 300 ],
            [ mysqld =>  max_connections    => 1500 ],
            [ mysqld =>  wait_timeout       => 28800 ],

            # from parts/admin.conf
            [ mysqladmin => user  => "root" ],
            [ mysqladmin => password => "5ekr3t" ],

            # from parts/old_passwords.cnf
            #[ mysqld =>  old_passwords  => "false" ],
            # XXX can't be tested because of the differences of how
            # Config::Tiny and Config::IniFiles treats multiple assignations
        ],
    },
);

my $structs_count = scalar map { @{ $_->{struct} } } @cases;
my $structs_tests = 1;
my $backend_tests = 3 * @cases + $structs_tests * $structs_count;

plan tests => 6 + $backend_tests * @backends;

# load the module and check its API
use_ok($module);
can_ok($module, @methods);

# check diagnostics
my $r = eval { $module->new() };
like( $@, q</^error: Arguments must be given as a hash reference/>, 
    "calling new() with no arguments" );

$r = eval { $module->new({}) };
like( $@, q</^error: Missing required argument 'from'/>, 
    "calling new() with no arguments" );

$r = eval { $module->new({ from => undef }) };
like( $@, q</^error: Empty argument 'from'/>, 
    "calling new() with from=undef" );

$r = eval { $module->new({ from => "" }) };
like( $@, q</^error: Empty argument 'from'/>, 
    "calling new() with from=''" );


SKIP: {
    # try to load a MySQL config using several backends
    for my $backend (@backends) {
        $backend->require or skip "can't load $backend", $backend_tests;

        for my $case (@cases) {
            my $file = $case->{file};
            my $config = eval {
                $module->new({ from => $file, using => $backend })
            };

            is( $@, "", "reading '$file' with $backend" );
            isa_ok( $config, $module,  " .. the object" );
            isa_ok( $config, $backend, " .. the object" );

            for my $check (@{$case->{struct}}) {
                my ($section, $param, $value) = @$check;
                is( get_param_from($config, $section, $param), $value,
                    " .. check the value of $section/$param" );
            }
        }
    }
}


sub get_param_from {
    my ($config, $section, $param) = @_;

    if (eval { $config->isa("Config::IniFiles") }) {
        return $config->val($section => $param)
    }
    elsif (eval { $config->isa("Config::Format::Ini") }) {
        return $config->{$section}{$param}[0]
    }
    elsif (eval { $config->isa("Config::INI::Reader") }) {
        return $config->{$section}{$param}
    }
    elsif (eval { $config->isa("Config::Simple") }) {
        return $config->get_block($section)->{$param}
    }
    elsif (eval { $config->isa("Config::Tiny") }) {
        return $config->{$section}{$param}
    }
}
