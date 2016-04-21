package Date::Utils;

$Date::Utils::VERSION   = '0.16';
$Date::Utils::AUTHORITY = 'cpan:MANWAR';

=head1 NAME

Date::Utils - Common date functions as Moo Role.

=head1 VERSION

Version 0.16

=cut

use 5.006;
use Data::Dumper;
use POSIX qw/floor/;
use Term::ANSIColor::Markup;

use Moo::Role;
use namespace::clean;

use Date::Exception::InvalidDay;
use Date::Exception::InvalidMonth;
use Date::Exception::InvalidYear;

has gregorian_epoch => (is => 'ro', default => sub { 1721425.5 });

=head1 DESCRIPTION

Common date functions as Moo Role.

=head1 METHODS

=head2 jwday($julian_date)

Returns day of week for the given Julian date C<$julian_date>, with 0 for Sunday.

=cut

sub jwday {
    my ($self, $julian_date) = @_;

    return floor($julian_date + 1.5) % 7;
}

=head2 create_calendar(\%params)

Returns the color coded calendar as a scalar string.It expects one parameter as a
hash ref with keys mentioned in the below table. All keys are mandatory.

    +-------------+-------------------------------------------------------------+
    | Key         | Description                                                 |
    +-------------+-------------------------------------------------------------+
    | start_index | Index (1-7) for the first day of the month, 1 for Sunday.   |
    | days        | Total days count for the given month.                       |
    | month_name  | Name of the given month.                                    |
    | day_names   | Ref to a list of day name starting with Sunday.             |
    | year        | Given year.                                                 |
    +-------------+-------------------------------------------------------------+

=cut

sub create_calendar {
    my ($self, $params) = @_;

    my $start_index = $params->{start_index};
    my $days        = $params->{days};
    my $month_name  = $params->{month_name};
    my $day_names   = $params->{day_names};
    my $year        = $params->{year};

    my $max_length_day_name = _max_days_name($day_names);
    my $line_size = (7 * ($max_length_day_name + 2)) + 8;
    my ($f, $s, $month_header) = _month_header($line_size, $month_name, $year);

    my $line1 = _get_dashed_line($line_size);
    my $line2 = _get_month_header($f, $month_header, $s);
    my $line3 = _get_blocked_line($max_length_day_name);
    my $line4 = _get_day_header($day_names, $max_length_day_name);
    my $empty = _get_empty_space($start_index, $max_length_day_name);
    my $dates = _get_dates($start_index, $days, $max_length_day_name);
    my $calendar = join("\n", $line1, $line2, $line3, $line4, $line3, $empty.$dates)."\n";

    return Term::ANSIColor::Markup->colorize($calendar);
}

=head2 gregorian_to_julian($year, $month, $day)

Returns Julian date equivalent of the given Gregorian date.

=cut

sub gregorian_to_julian {
    my ($self, $year, $month, $day) = @_;

    return ($self->gregorian_epoch - 1) +
           (365 * ($year - 1)) +
           floor(($year - 1) / 4) +
           (-floor(($year - 1) / 100)) +
           floor(($year - 1) / 400) +
           floor((((367 * $month) - 362) / 12) +
           (($month <= 2) ? 0 : ($self->is_gregorian_leap_year($year) ? -1 : -2)) +
           $day);
}

=head2 julian_to_gregorian($julian_date)

Returns Gregorian date as list  (year, month, day) equivalent of the given Julian
date C<$julian_date>.

=cut

sub julian_to_gregorian {
    my ($self, $julian) = @_;

    my $wjd        = floor($julian - 0.5) + 0.5;
    my $depoch     = $wjd - $self->gregorian_epoch;
    my $quadricent = floor($depoch / 146097);
    my $dqc        = $depoch % 146097;
    my $cent       = floor($dqc / 36524);
    my $dcent      = $dqc % 36524;
    my $quad       = floor($dcent / 1461);
    my $dquad      = $dcent % 1461;
    my $yindex     = floor($dquad / 365);
    my $year       = ($quadricent * 400) + ($cent * 100) + ($quad * 4) + $yindex;

    $year++ unless (($cent == 4) || ($yindex == 4));

    my $yearday = $wjd - $self->gregorian_to_julian($year, 1, 1);
    my $leapadj = (($wjd < $self->gregorian_to_julian($year, 3, 1)) ? 0 : (($self->is_gregorian_leap_year($year) ? 1 : 2)));
    my $month   = floor(((($yearday + $leapadj) * 12) + 373) / 367);
    my $day     = ($wjd - $self->gregorian_to_julian($year, $month, 1)) + 1;

    return ($year, $month, $day);
}

=head2 is_gregorian_leap_year($year)

Returns 0 or 1 if the given Gregorian year C<$year> is a leap year or not.

=cut

sub is_gregorian_leap_year {
    my ($self, $year) = @_;

    return (($year % 4) == 0) && (!((($year % 100) == 0) && (($year % 400) != 0)));
}

=head2 validate_year($year)

Validates the given C<$year>. It has to be > 0 and numbers only.

=cut

sub validate_year {
    my ($self, $year) = @_;

    my @caller = caller(0);
    @caller    = caller(2) if $caller[3] eq '(eval)';

    Date::Exception::InvalidYear->throw({
        method      => __PACKAGE__."::validate_year",
        message     => sprintf("ERROR: Invalid year [%s].", defined($year)?($year):('')),
        filename    => $caller[1],
        line_number => $caller[2] })
        unless (defined($year) && ($year =~ /^\d+$/) && ($year > 0));
}

=head2 validate_month($month)

Validates the given C<$month>. It has to be between 1 and 12.

=cut

sub validate_month {
    my ($self, $month) = @_;

    my @caller = caller(0);
    @caller    = caller(2) if $caller[3] eq '(eval)';

    Date::Exception::InvalidMonth->throw({
        method      => __PACKAGE__."::validate_month",
        message     => sprintf("ERROR: Invalid month [%s].", defined($month)?($month):('')),
        filename    => $caller[1],
        line_number => $caller[2] })
        unless (defined($month) && ($month =~ /^\d+$/) && ($month >= 1) && ($month <= 12));
}

=head2 validate_day($day)

Validates the given C<$day>. It has to be between 1 and 31.

=cut

sub validate_day {
    my ($self, $day) = @_;

    my @caller = caller(0);
    @caller    = caller(2) if $caller[3] eq '(eval)';

    Date::Exception::InvalidDay->throw({
        method      => __PACKAGE__."::validate_day",
        message     => sprintf("ERROR: Invalid day [%s].", defined($day)?($day):('')),
        filename    => $caller[1],
        line_number => $caller[2] })
        unless (defined($day) && ($day =~ /^\d+$/) && ($day >= 1) && ($day <= 31));
}

=head2 validate_date($year, $month, $day)

Validates the given C<$year>, C<$month> and C<$day>.

=cut

sub validate_date {
    my ($self, $year, $month, $day) = @_;

    $self->validate_year($year);
    $self->validate_month($month);
    $self->validate_day($day);
}

#
#
# PRIVATE METHODS

sub _max_days_name {
    my ($days_name) = @_;

    my $l = 0;
    foreach (@$days_name) {
        if ($l < length($_)) {
            $l = length($_);
        }
    }
    return $l;
}

sub _month_header {
    my ($line_size, $month_name, $year) = @_;

    my $_month = sprintf("%s [%d BE]", $month_name, $year);
    my $h = int($line_size/2);
    my $m = int(length($_month)/2);

    my $f = $h - $m;
    my $s = $line_size - ($f + length($_month));

    return ($f, $s, $_month);
}

sub _get_dashed_line  { '<blue><bold>+'.('-')x($_[0]-2).'+</bold></blue>' }

sub _get_month_header { '<blue><bold>|</bold></blue>'.(' ')x($_[0]-1).'<yellow><bold>'.$_[1].'</bold></yellow>'.(' ')x($_[2]-1).'<blue><bold>|</bold></blue>' }

sub _get_blocked_line { my $line = '<blue><bold>+'; for(1..7) { $line .= ('-')x($_[0]+2).'+'; } $line .= '</bold></blue>'; return $line; }

sub _get_day_header   {
    my ($day_names, $max_length_day_name) = @_;

    my $line = '<blue><bold>|</bold></blue>';
    my $i = 1;
    foreach (@$day_names) {
        my $x = length($_);
        my $y = $max_length_day_name - $x;
        my $z = $y + 1;
        if ($i == 1) {
            $line .= ((' ')x$z). "<yellow><bold>$_</bold></yellow>";
            $i++;
        }
        else {
            $line .= " <blue><bold>|</bold></blue>".((' ')x$z)."<yellow><bold>$_</bold></yellow>";
        }

    }
    $line .= " <blue><bold>|</bold></blue>";

    return $line;
}

sub _get_empty_space {
    my ($start_index, $max_length_day_name) = @_;

    my $line = '';
    if ($start_index % 7 != 0) {
        $line .= '<blue><bold>|</bold></blue>'.(' ')x($max_length_day_name+2);
        map { $line .= ' 'x($max_length_day_name+3) } (2..($start_index %= 7));
    }

    return $line;
}

sub _get_dates {
    my ($start_index, $days, $max_length_day_name) = @_;

    my $line = '';
    my $blocked_line = _get_blocked_line($max_length_day_name);
    foreach (1 .. $days) {
        $line .= sprintf("<blue><bold>|</bold></blue><cyan><bold>%".($max_length_day_name+1)."s </bold></cyan>", $_);
        if ($_ != $days) {
            $line .= "<blue><bold>|</bold></blue>\n".$blocked_line."\n" unless (($start_index + $_) % 7);
        }
        elsif ($_ == $days) {
            my $x = 7 - (($start_index + $_) % 7);
            if (($x >= 2) && ($x != 7)) {
                $line .= '<blue><bold>|</bold></blue>'. (' 'x($max_length_day_name+2));
                map { $line .= ' 'x($max_length_day_name+3) } (1..$x-1);
            }
            elsif ($x != 7) {
                $line .= '<blue><bold>|</bold></blue>'.' 'x($max_length_day_name+2);
            }
        }
    }

    return sprintf("%s<blue><bold>|</bold></blue>\n%s\n", $line, $blocked_line);
}

=head1 AUTHOR

Mohammad S Anwar, C<< <mohammad.anwar at yahoo.com> >>

=head1 REPOSITORY

L<https://github.com/manwar/Date-Utils>

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

Copyright (C) 2015 - 2016 Mohammad S Anwar.

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
