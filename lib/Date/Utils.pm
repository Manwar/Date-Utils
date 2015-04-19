package Date::Utils;

$Date::Utils::VERSION = '0.06';

use strict; use warnings;
use 5.006;
use Data::Dumper;
use List::Util qw/min/;
use POSIX qw/floor ceil/;
use Date::Calc qw/Delta_Days/;
use parent 'Exporter';
use vars qw(@EXPORT_OK);

=head1 NAME

Date::Utils - Helper package for dates.

=head1 VERSION

Version 0.06

=head1 DESCRIPTION

Collection of common date related functions.

=cut

@EXPORT_OK = qw(
    $BAHAI_EPOCH
    $HIJRI_EPOCH
    $PERSIAN_EPOCH
    $GREGORIAN_EPOCH

    $BAHAI_DAYS
    $BAHAI_MONTHS
    $BAHAI_CYCLES
    $BAHAI_YEAR
    $BAHAI_MONTH
    $BAHAI_DAY
    get_major_cycle_year
    validate_bahai_year
    validate_bahai_month
    validate_bahai_day
    bahai_to_gregorian
    bahai_to_julian

    $PERSIAN_DAYS
    $PERSIAN_MONTHS
    $PERSIAN_YEAR
    $PERSIAN_MONTH
    $PERSIAN_DAY
    persian_to_gregorian
    persian_to_julian
    days_in_persian_month_year

    $HIJRI_DAYS
    $HIJRI_MONTHS
    $HIJRI_YEAR
    $HIJRI_MONTH
    $HIJRI_DAY
    hijri_to_gregorian
    hijri_to_julian
    days_in_hijri_year
    days_in_hijri_month_year

    $SAKA_MONTHS
    $SAKA_DAYS
    $SAKA_YEAR
    $SAKA_MONTH
    $SAKA_DAY
    saka_to_gregorian
    saka_to_julian
    days_in_saka_month_year

    julian_to_bahai
    julian_to_hijri
    julian_to_saka
    julian_to_persian
    julian_to_gregorian
    gregorian_to_bahai
    gregorian_to_hijri
    gregorian_to_saka
    gregorian_to_persian
    gregorian_to_julian

    jwday
    is_gregorian_leap_year
    is_persian_leap_year
    is_hijri_leap_year
);

our $BAHAI_EPOCH     = 2394646.5;
our $HIJRI_EPOCH     = 1948439.5;
our $PERSIAN_EPOCH   = 1948320.5;
our $GREGORIAN_EPOCH = 1721425.5;

our $BAHAI_MONTHS = [
    '',
    'Baha',    'Jalal', 'Jamal',  'Azamat', 'Nur',       'Rahmat',
    'Kalimat', 'Kamal', 'Asma',   'Izzat',  'Mashiyyat', 'Ilm',
    'Qudrat',  'Qawl',  'Masail', 'Sharaf', 'Sultan',    'Mulk',
    'Ala'
];

our $BAHAI_CYCLES = [
    '',
    'Alif', 'Ba',     'Ab',    'Dal',  'Bab',    'Vav',
    'Abad', 'Jad',    'Baha',  'Hubb', 'Bahhaj', 'Javab',
    'Ahad', 'Vahhab', 'Vidad', 'Badi', 'Bahi',   'Abha',
    'Vahid'
];

our $BAHAI_DAYS = [
    '<yellow><bold>    Jamal </bold></yellow>',
    '<yellow><bold>    Kamal </bold></yellow>',
    '<yellow><bold>    Fidal </bold></yellow>',
    '<yellow><bold>     Idal </bold></yellow>',
    '<yellow><bold> Istijlal </bold></yellow>',
    '<yellow><bold> Istiqlal </bold></yellow>',
    '<yellow><bold>    Jalal </bold></yellow>'
];

our $BAHAI_YEAR    = sub { validate_bahai_year(@_)  };
our $BAHAI_MONTH   = sub { validate_bahai_month(@_) };
our $BAHAI_DAY     = sub { validate_bahai_day(@_)   };
our $PERSIAN_YEAR  = sub { _validate_year(@_)       };
our $PERSIAN_MONTH = sub { _validate_month(@_)      };
our $PERSIAN_DAY   = sub { _validate_day(@_)        };
our $HIJRI_YEAR    = sub { _validate_year(@_)       };
our $HIJRI_MONTH   = sub { _validate_month(@_)      };
our $HIJRI_DAY     = sub { _validate_hijri_day(@_)  };
our $SAKA_YEAR     = sub { _validate_year(@_)       };
our $SAKA_MONTH    = sub { _validate_month(@_)      };
our $SAKA_DAY      = sub { _validate_day(@_)        };

our $PERSIAN_MONTHS = [
    '',
    'Farvardin',  'Ordibehesht',  'Khordad',  'Tir',  'Mordad',  'Shahrivar',
    'Mehr'     ,  'Aban'       ,  'Azar'   ,  'Dey',  'Bahman',  'Esfand'
];

our $PERSIAN_DAYS = [
    '<yellow><bold>    Yekshanbeh </bold></yellow>',
    '<yellow><bold>     Doshanbeh </bold></yellow>',
    '<yellow><bold>    Seshhanbeh </bold></yellow>',
    '<yellow><bold> Chaharshanbeh </bold></yellow>',
    '<yellow><bold>   Panjshanbeh </bold></yellow>',
    '<yellow><bold>         Jomeh </bold></yellow>',
    '<yellow><bold>       Shanbeh </bold></yellow>'
];

our $HIJRI_MONTHS = [
    undef,
    q/Muharram/, q/Safar/ , q/Rabi' al-awwal/, q/Rabi' al-thani/,
    q/Jumada al-awwal/, q/Jumada al-thani/, q/Rajab/ , q/Sha'aban/,
    q/Ramadan/ , q/Shawwal/ , q/Dhu al-Qi'dah/ , q/Dhu al-Hijjah/
];

our $HIJRI_DAYS = [
    '<yellow><bold>      al-Ahad </bold></yellow>',
    '<yellow><bold>   al-Ithnayn </bold></yellow>',
    '<yellow><bold> ath-Thulatha </bold></yellow>',
    '<yellow><bold>     al-Arbia </bold></yellow>',
    '<yellow><bold>    al-Khamis </bold></yellow>',
    '<yellow><bold>    al-Jumuah </bold></yellow>',
    '<yellow><bold>      as-Sabt </bold></yellow>',
];

our $HIJRI_LEAP_YEAR_MOD = [
    2, 5, 7, 10, 13, 16, 18, 21, 24, 26, 29
];

our $SAKA_START  = 80;
our $SAKA_OFFSET = 78;

our $SAKA_MONTHS = [
    undef,
    'Chaitra', 'Vaisakha', 'Jyaistha',   'Asadha', 'Sravana', 'Bhadra',
    'Asvina',  'Kartika',  'Agrahayana', 'Pausa',  'Magha',   'Phalguna'
];

our $SAKA_DAYS = [
    '<yellow><bold>       Ravivara </bold></yellow>',
    '<yellow><bold>        Somvara </bold></yellow>',
    '<yellow><bold>    Mangalavara </bold></yellow>',
    '<yellow><bold>      Budhavara </bold></yellow>',
    '<yellow><bold> Brahaspativara </bold></yellow>',
    '<yellow><bold>      Sukravara </bold></yellow>',
    '<yellow><bold>       Sanivara </bold></yellow>',
];

=head1 METHODS

=head2 validate_bahai_year($year)

Dies if the given C<$year> is not a valid Bahai year.

=cut

sub validate_bahai_year {
    my ($year) = @_;

    die("ERROR: Invalid year [$year].\n")
        unless (defined($year) && ($year =~ /^\d+$/) && ($year > 0));
}

=head2 validate_bahai_month($month)

Dies if the given C<$month> is not a valid Bahai month.

=cut

sub validate_bahai_month {
    my ($month) = @_;

    die("ERROR: Invalid month [$month].\n")
        unless (defined($month) && ($month =~ /^\d{1,2}$/) && ($month >= 1) && ($month <= 19));
}

=head2 validate_bahai_day($day)

Dies if the given C<$day> is not a valid Bahai day.

=cut

sub validate_bahai_day {
    my ($day) = @_;

    die ("ERROR: Invalid day [$day].\n")
        unless (defined($day) && ($day =~ /^\d{1,2}$/) && ($day >= 1) && ($day <= 19));
}

=head2 jwday($julian_date)

Returns day of week for the given Julian date C<$julian_date>, with 0 for Sunday.

=cut

sub jwday {
    my ($julian_date) = @_;

    return floor($julian_date + 1.5) % 7;
}

=head2 gregorian_to_bahai($year, $month, $day)

Returns Bahai date component as list (majaor, cycle, year, month, day) equivalent
of the given gregorian date.

=cut

sub gregorian_to_bahai {
    my ($year, $month, $day) = @_;

    return julian_to_bahai(gregorian_to_julian($year, $month, $day));
}

=head2 bahai_to_gregorian($major, $cycle, $year, $month, $day)

Returns Gregorian  date  as list (year, month, day) equivalent of the given bahai
date.

=cut

sub bahai_to_gregorian {
    my ($major, $cycle, $year, $month, $day) = @_;

    return julian_to_gregorian(bahai_to_julian($major, $cycle, $year, $month, $day));
}

=head2 julian_to_bahai($julian_date)

Returns Bahai date component as list (majaor, cycle, year, month, day) equivalent
of the given Julian date C<$julian_date>.

=cut

sub julian_to_bahai {
    my ($julian_date) = @_;

    $julian_date = floor($julian_date) + 0.5;
    my $gregorian_year = (julian_to_gregorian($julian_date))[0];
    my $start_year     = (julian_to_gregorian($BAHAI_EPOCH))[0];

    my $j1 = gregorian_to_julian($gregorian_year, 1, 1);
    my $j2 = gregorian_to_julian($gregorian_year, 3, 20);

    my $bahai_year = $gregorian_year - ($start_year + ((($j1 <= $julian_date) && ($julian_date <= $j2)) ? 1 : 0));
    my ($major, $cycle, $year) = get_major_cycle_year($bahai_year);

    my $days  = $julian_date - bahai_to_julian($major, $cycle, $year, 1, 1);
    my $bld   = bahai_to_julian($major, $cycle, $year, 20, 1);
    my $month = ($julian_date >= $bld) ? 20 : (floor($days / 19) + 1);
    my $day   = ($julian_date + 1) - bahai_to_julian($major, $cycle, $year, $month, 1);

    return ($major, $cycle, $year, $month, $day);
}

=head2 bahai_to_julian($major, $cycle, $year, $month, $day)

Returns julian date of the given bahai date.

=cut

sub bahai_to_julian {
    my ($major, $cycle, $year, $month, $day) = @_;

    my ($g_year) = julian_to_gregorian($BAHAI_EPOCH);
    my $gy     = (361 * ($major - 1)) +
                 (19  * ($cycle - 1)) +
                 ($year - 1) + $g_year;

    return gregorian_to_julian($gy, 3, 20)
           +
           (19 * ($month - 1))
           +
           (($month != 20) ? 0 : (is_gregorian_leap_year($gy + 1) ? -14 : -15))
           +
           $day;
}

=head2 gregorian_to_julian($year, $month, $day)

Returns Julian date equivalent of the given Gregorian date.

=cut

sub gregorian_to_julian {
    my ($year, $month, $day) = @_;

    return ($GREGORIAN_EPOCH - 1) +
           (365 * ($year - 1)) +
           floor(($year - 1) / 4) +
           (-floor(($year - 1) / 100)) +
           floor(($year - 1) / 400) +
           floor((((367 * $month) - 362) / 12) +
           (($month <= 2) ? 0 : (is_gregorian_leap_year($year) ? -1 : -2)) +
           $day);
}

=head2 julian_to_gregorian($julian_date)

Returns Gregorian date as list  (year, month, day) equivalent of the given Julian
date C<$julian_date>.

=cut

sub julian_to_gregorian {
    my ($julian) = @_;

    my $wjd        = floor($julian - 0.5) + 0.5;
    my $depoch     = $wjd - $GREGORIAN_EPOCH;
    my $quadricent = floor($depoch / 146097);
    my $dqc        = $depoch % 146097;
    my $cent       = floor($dqc / 36524);
    my $dcent      = $dqc % 36524;
    my $quad       = floor($dcent / 1461);
    my $dquad      = $dcent % 1461;
    my $yindex     = floor($dquad / 365);
    my $year       = ($quadricent * 400) + ($cent * 100) + ($quad * 4) + $yindex;

    $year++ unless (($cent == 4) || ($yindex == 4));

    my $yearday = $wjd - gregorian_to_julian($year, 1, 1);
    my $leapadj = (($wjd < gregorian_to_julian($year, 3, 1)) ? 0 : ((is_gregorian_leap_year($year) ? 1 : 2)));
    my $month   = floor(((($yearday + $leapadj) * 12) + 373) / 367);
    my $day     = ($wjd - gregorian_to_julian($year, $month, 1)) + 1;

    return ($year, $month, $day);
}

=head2 get_major_cycle_year($bahai_year)

Returns the attribute as list major, cycle & year as in Kull-i-Shay) of the given
Bahai year C<$bahai_year>.

=cut

sub get_major_cycle_year {
    my ($bahai_year) = @_;

    my $major = floor($bahai_year / 361) + 1;
    my $cycle = floor(($bahai_year % 361) / 19) + 1;
    my $year  = ($bahai_year % 19) + 1;

    return ($major, $cycle, $year);
}

=head2 is_gregorian_leap_year($year)

Returns 0 or 1 if the given Gregorian year C<$year> is a leap year or not.

=cut

sub is_gregorian_leap_year {
    my ($year) = @_;

    return (($year % 4) == 0) &&
            (!((($year % 100) == 0) && (($year % 400) != 0)));
}

=head2 persian_to_gregorian($year, $month, $day)

Returns Gregorian date as list (year, month, day) equivalent of the given Persian
date.

=cut

sub persian_to_gregorian {
    my ($year, $month, $day) = @_;

    _validate_date($year, $month, $day);
    ($year, $month, $day) =  julian_to_gregorian(persian_to_julian($year, $month, $day));

    return ($year, $month, $day);
}

=head2 gregorian_to_persian($year, $month, $day)

Returns Persian date as list (year, month, day) equivalent of the given Gregorian
date.

=cut

sub gregorian_to_persian {
    my ($year, $month, $day) = @_;

    _validate_date($year, $month, $day);
    my $julian = gregorian_to_julian($year, $month, $day) + (floor(0 + 60 * (0 + 60 * 0) + 0.5) / 86400.0);
    ($year, $month, $day) = julian_to_persian($julian);

    return ($year, $month, $day);
}

=head2 persian_to_julian($year, $month. $day)

Returns Julian date of the given Persian date.

=cut

sub persian_to_julian {
    my ($year, $month, $day) = @_;

    my $epbase = $year - (($year >= 0) ? 474 : 473);
    my $epyear = 474 + ($epbase % 2820);

    return $day + (($month <= 7)?(($month - 1) * 31):((($month - 1) * 30) + 6)) +
           floor((($epyear * 682) - 110) / 2816) +
           ($epyear - 1) * 365 +
           floor($epbase / 2820) * 1029983 +
           ($PERSIAN_EPOCH - 1);
}

=head2 julian_to_persian($julian_date)

Returns Persian date as list  (year, month, day)  equivalent of the  given Julian
date.

=cut

sub julian_to_persian {
    my ($julian) = @_;

    $julian = floor($julian) + 0.5;
    my $depoch = $julian - persian_to_julian(475, 1, 1);
    my $cycle  = floor($depoch / 1029983);
    my $cyear  = $depoch % 1029983;

    my $ycycle;
    if ($cyear == 1029982) {
        $ycycle = 2820;
    }
    else {
        my $aux1 = floor($cyear / 366);
        my $aux2 = $cyear % 366;
        $ycycle = floor(((2134 * $aux1) + (2816 * $aux2) + 2815) / 1028522) + $aux1 + 1;
    }

    my $year = $ycycle + (2820 * $cycle) + 474;
    if ($year <= 0) {
        $year--;
    }

    my $yday  = ($julian - persian_to_julian($year, 1, 1)) + 1;
    my $month = ($yday <= 186) ? ceil($yday / 31) : ceil(($yday - 6) / 30);
    my $day   = ($julian - persian_to_julian($year, $month, 1)) + 1;

    return ($year, $month, $day);
}

=head2 hijri_to_julian($year, $month, $day)

Returns Julian date of the given Hijri date.

=cut

sub hijri_to_julian {
    my ($year, $month, $day) = @_;

    return ($day +
            ceil(29.5 * ($month - 1)) +
            ($year - 1) * 354 +
            floor((3 + (11 * $year)) / 30) +
            $HIJRI_EPOCH) - 1;
}

=head2 hijri_to_gregorian($year, $month, $day)

Returns  Gregorian  date as list (year, month, day) equivalent of the given Hijri
date.

=cut

sub hijri_to_gregorian {
    my ($year, $month, $day) = @_;

    _validate_hijri_date($year, $month, $day);
    ($year, $month, $day) = julian_to_gregorian(hijri_to_julian($year, $month, $day));

    return ($year, $month, $day);
}

=head2 gregorian_to_hijri($year, $month, $day)

Returns  Hijri  date as list (year, month, day) equivalent of the given Gregorian
date.

=cut

sub gregorian_to_hijri {
    my ($year, $month, $day) = @_;

    ($year, $month, $day) = julian_to_hijri(gregorian_to_julian($year, $month, $day));
    return ($year, $month, $day);
}

=head2 julian_to_hijri($julian_date)

Returns Hijri date as list (year, month, day) equivalent of the given Julian date.

=cut

sub julian_to_hijri {
    my ($julian) = @_;

    $julian   = floor($julian) + 0.5;
    my $year  = floor(((30 * ($julian - $HIJRI_EPOCH)) + 10646) / 10631);
    my $month = min(12, ceil(($julian - (29 + hijri_to_julian($year, 1, 1))) / 29.5) + 1);
    my $day   = ($julian - hijri_to_julian($year, $month, 1)) + 1;

    return ($year, $month, $day);
}

=head2 is_persian_leap_year($year)

Returns 0 or 1 if the given Persian year C<$year> is a leap year or not.

=cut

sub is_persian_leap_year {
    my ($year) = @_;

    return (((((($year - (($year > 0) ? 474 : 473)) % 2820) + 474) + 38) * 682) % 2816) < 682;
}

=head2 days_in_persian_month_year($month, $year)

Returns total number of days in the given Persian month year.

=cut

sub days_in_persian_month_year {
    my ($month, $year) = @_;

    _validate_year($year);
    _validate_month($month);

    my @start = persian_to_gregorian($year, $month, 1);
    if ($month == 12) {
        $year += 1;
        $month = 1;
    }
    else {
        $month += 1;
    }

    my @end = persian_to_gregorian($year, $month, 1);

    return Delta_Days(@start, @end);
}

=head2 is_hijri_leap_year($year)

Returns 0 or 1 if the given Hijri year C<$year> is a leap year or not.

=cut

sub is_hijri_leap_year {
    my ($year) = @_;

    my $mod = $year % 30;
    return 1 if grep/$mod/, @$HIJRI_LEAP_YEAR_MOD;
    return 0;
}

=head2 days_in_hijri_year($year)

Returns the number of days in the given year of Hijri Calendar.

=cut

sub days_in_hijri_year {
    my ($year) = @_;

    (is_hijri_leap_year($year))
    ?
    (return 355)
    :
    (return 354);
}

=head2 days_in_hijri_month_year($month, $year)

Returns total number of days in the given Hijri month year.

=cut

sub days_in_hijri_month_year {
    my ($month, $year) = @_;

    return 30 if (($month % 2 == 1) || (($month == 12) && (is_hijri_leap_year($year))));
    return 29;

}

=head2 saka_to_gregorian($year, $month, $day)

=cut

sub saka_to_gregorian {
    my ($year, $month, $day) = @_;

    return julian_to_gregorian(saka_to_julian($year, $month, $day));
}

=head2 gregorian_to_sake($year, $month, $day)

=cut

sub gregorian_to_saka {
    my ($year, $month, $day) = @_;

    return julian_to_saka(gregorian_to_julian($year, $month, $day));
}

=head2 saka_to_julian($year, $month, $day)

=cut

sub saka_to_julian {
    my ($year, $month, $day) = @_;

    my $gregorian_year = $year + 78;
    my $gregorian_day  = (is_gregorian_leap_year($gregorian_year)) ? (21) : (22);
    my $start = gregorian_to_julian($gregorian_year, 3, $gregorian_day);

    my ($julian);
    if ($month == 1) {
        $julian = $start + ($day - 1);
    }
    else {
        my $chaitra = (is_gregorian_leap_year($gregorian_year)) ? (31) : (30);
        $julian = $start + $chaitra;
        my $_month = $month - 2;
        $_month = min($_month, 5);
        $julian += $_month * 31;

        if ($month >= 8) {
            $_month  = $month - 7;
            $julian += $_month * 30;
        }

        $julian += $day - 1;
    }

    return $julian;
}

=head2 julian_to_saka()

=cut

sub julian_to_saka {
    my ($julian) = @_;

    $julian     = floor($julian) + 0.5;
    my $year    = (julian_to_gregorian($julian))[0];
    my $yday    = $julian - gregorian_to_julian($year, 1, 1);
    my $chaitra = days_in_chaitra($year);
    $year = $year - $SAKA_OFFSET;

    if ($yday < $SAKA_START) {
        $year--;
        $yday += $chaitra + (31 * 5) + (30 * 3) + 10 + $SAKA_START;
    }
    $yday -= $SAKA_START;

    my ($day, $month);
    if ($yday < $chaitra) {
        $month = 1;
        $day   = $yday + 1;
    }
    else {
        my $mday = $yday - $chaitra;
        if ($mday < (31 * 5)) {
            $month = floor($mday / 31) + 2;
            $day   = ($mday % 31) + 1;
        }
        else {
            $mday -= 31 * 5;
            $month = floor($mday / 30) + 7;
            $day   = ($mday % 30) + 1;
        }
    }

    return ($year, $month, $day);
}

=head2 days_in_chaitra($year)

=cut

sub days_in_chaitra {
    my ($year) = @_;

    (is_gregorian_leap_year($year)) ? (return 31) : (return 30);
}

=head2 days_in_saka_month_year($month, $year)

=cut

sub days_in_saka_month_year {
    my ($month, $year) = @_;

    my @start = saka_to_gregorian($year, $month, 1);
    if ($month == 12) {
        $year += 1;
        $month = 1;
    }
    else {
        $month += 1;
    }

    my @end = saka_to_gregorian($year, $month, 1);

    return Delta_Days(@start, @end);
}

#
#
# PRIVATE METHODS

sub _validate_bahai_date {
    my ($year, $month, $day) = @_;

    validate_bahai_day($day);
    validate_bahai_month($month);
    validate_bahai_year($year);
}

sub _validate_hijri_date {
    my ($year, $month, $day) = @_;

    _validate_year($year);
    _validate_month($month);
    _validate_hijri_day($day);
}

sub _validate_date {
    my ($year, $month, $day) = @_;

    _validate_year($year);
    _validate_month($month);
    _validate_day($day);
}

sub _validate_year {
    my ($year) = @_;

    die("ERROR: Invalid year [$year].\n")
        unless (defined($year) && ($year =~ /^\d{4}$/) && ($year > 0));
}

sub _validate_month {
    my ($month) = @_;

    die("ERROR: Invalid month [$month].\n")
        unless (defined($month) && ($month =~ /^\d{1,2}$/) && ($month >= 1) && ($month <= 12));
}

sub _validate_day {
    my ($day) = @_;

    die("ERROR: Invalid day [$day].\n")
        unless (defined($day) && ($day =~ /^\d{1,2}$/) && ($day >= 1) && ($day <= 31));
}

sub _validate_hijri_day {
    my ($day) = @_;

    die("ERROR: Invalid day [$day].\n")
        unless (defined($day) && ($day =~ /^\d{1,2}$/) && ($day >= 1) && ($day <= 30));
}

=head1 AUTHOR

Mohammad S Anwar, C<< <mohammad.anwar at yahoo.com> >>

=head1 REPOSITORY

L<https://github.com/Manwar/Date-Utils>

=head1 ACKNOWLEDGEMENTS

Entire logic is based on the L<code|http://www.fourmilab.ch/documents/calendar> written by John Walker.

=head1 BUGS

Please report any bugs / feature requests to C<bug-date-utils at rt.cpan.org>, or
through the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Date-Utils>.
I will be notified, and then you'll automatically be notified of progress on your
bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Date::Utils

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Date-Utils>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Date-Utils>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Date-Utils>

=item * Search CPAN

L<http://search.cpan.org/dist/Date-Utils/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2015 Mohammad S Anwar.

This program  is  free software; you can redistribute it and / or modify it under
the  terms  of the the Artistic License (2.0). You may obtain a  copy of the full
license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any  use,  modification, and distribution of the Standard or Modified Versions is
governed by this Artistic License.By using, modifying or distributing the Package,
you accept this license. Do not use, modify, or distribute the Package, if you do
not accept this license.

If your Modified Version has been derived from a Modified Version made by someone
other than you,you are nevertheless required to ensure that your Modified Version
 complies with the requirements of this license.

This  license  does  not grant you the right to use any trademark,  service mark,
tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge patent license
to make,  have made, use,  offer to sell, sell, import and otherwise transfer the
Package with respect to any patent claims licensable by the Copyright Holder that
are  necessarily  infringed  by  the  Package. If you institute patent litigation
(including  a  cross-claim  or  counterclaim) against any party alleging that the
Package constitutes direct or contributory patent infringement,then this Artistic
License to you shall terminate on the date that such litigation is filed.

Disclaimer  of  Warranty:  THE  PACKAGE  IS  PROVIDED BY THE COPYRIGHT HOLDER AND
CONTRIBUTORS  "AS IS'  AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES. THE IMPLIED
WARRANTIES    OF   MERCHANTABILITY,   FITNESS   FOR   A   PARTICULAR  PURPOSE, OR
NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY YOUR LOCAL LAW. UNLESS
REQUIRED BY LAW, NO COPYRIGHT HOLDER OR CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT,
INDIRECT, INCIDENTAL,  OR CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE
OF THE PACKAGE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=cut

1; # End of Date::Utils
