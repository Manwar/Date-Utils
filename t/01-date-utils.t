#!/usr/bin/perl

package T::Date::Utils;

use Moo;
use namespace::clean;
with 'Date::Utils';

package main;

use 5.006;
use Test::More tests => 10;
use strict; use warnings;

my $t = T::Date::Utils->new;

is($t->gregorian_to_julian(2015, 4, 16), 2457128.5);

my @gregorian = $t->julian_to_gregorian(2457128.5);
is(join(', ', @gregorian), '2015, 4, 16');

ok(!!$t->is_gregorian_leap_year(2015) == 0);

is($t->jwday(2457102.5), 6);

ok($t->validate_year(2015));
eval { $t->validate_year(-2015) };
like($@, qr/ERROR: Invalid year/);

ok($t->validate_month(10));
eval { $t->validate_month(13) };
like($@, qr/ERROR: Invalid month/);

ok($t->validate_day(12));
eval { $t->validate_day(32) };
like($@, qr/ERROR: Invalid day/);

done_testing;
