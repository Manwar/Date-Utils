#!/usr/bin/perl

package T::Date::Utils;

use Moo;
use namespace::clean;

has 'months' => (is => 'ro', default => sub { [ '', qw(January February March April May June July August September October November December) ] });
has 'days'   => (is => 'ro', default => sub { [ qw(Sunday Monday Tuesday Wednesday Thursday Friday Saturday)] });

with 'Date::Utils';

package main;

use 5.006;
use Test::More tests => 19;
use strict; use warnings;

my $t = T::Date::Utils->new;

is($t->gregorian_to_julian(2015, 4, 16), 2457128.5);

my @gregorian = $t->julian_to_gregorian(2457128.5);
is(join(', ', @gregorian), '2015, 4, 16');

ok(!!$t->is_gregorian_leap_year(2015) == 0);

is($t->jwday(2457102.5), 6);

is($t->get_month_number('January'), 1);
is($t->get_month_number('December'), 12);
is($t->get_month_number('MAY'), 5);
is($t->get_month_name(5), 'May');

eval { $t->get_month_name(13) };
like($@, qr/ERROR: Invalid month/);

eval { $t->get_month_number('Max') };
like($@, qr/ERROR: Invalid month name/);

ok($t->validate_year(2015));
eval { $t->validate_year(-2015) };
like($@, qr/ERROR: Invalid year/);

ok($t->validate_month(10));
eval { $t->validate_month(13) };
like($@, qr/ERROR: Invalid month/);

eval { $t->validate_month_name('Max') };
like($@, qr/ERROR: Invalid month name/);

eval { $t->validate_month_name('January') };
like($@, qr/^\s*$/);

eval { $t->validate_month('DECEMBER') };
like($@, qr/^\s*$/);

ok($t->validate_day(12));
eval { $t->validate_day(32) };
like($@, qr/ERROR: Invalid day/);

done_testing;
