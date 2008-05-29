#!perl
use strict;
use warnings;
use lib 't/lib';

use Test::More tests => 2;

require_ok( 'Config::INI::MVP::Reader' );

my $have = Config::INI::MVP::Reader->read_file('eg/mvp.ini');
my $want = [
  {
    '=name' => '_',
    'bar'   => '11',
    'foo'   => '10',
  },
  {
    '=name'    => 'Foo::Bar',
    '=package' => 'Foo::Bar',
    'x' => '10',
    'y' => [ '20', '30' ],
    'z' => '-123',
  },
  {
    '=name'    => 'baz',
    '=package' => 'Foo::Bar',
    'x' => '1',
  }
];

is_deeply($have, $want, "read in example file okay");

