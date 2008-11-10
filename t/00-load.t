#!perl -T
use strict;
use Test::More tests => 1;

use_ok( "Config::Extend::MySQL" );
diag( "Testing Config::MySQL $Config::Extend::MySQL::VERSION, Perl $], $^X" );
