package Geo::Hex3;

use warnings;
use strict;
use Carp;

use POSIX qw/floor ceil/;
use Math::Round qw/round/;
use Math::Trig qw/pi tan atan/;
use Math::BaseCalc;

our $VERSION = "0.0.1";
use vars qw/@ISA @EXPORT/;
use Exporter;
@ISA = qw/Exporter/;
@EXPORT = qw/getZoneByLocation getZoneByCode/;

my $h_key   = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz";
my $h_base  = 20037508.34;
my $h_deg   = pi() * ( 30.0 / 180.0 );
my $h_k     = tan( $h_deg );
my $calc    = new Math::BaseCalc( digits => [0..2] );

sub getZoneByLocation {
    my ( $lat, $lon, $level ) = @_;
    $level += 2;

    my $h_size    = __setHexSize( $level );

    my $z_xy      = __loc2xy( $lon, $lat );
    my $lon_grid  = $z_xy->{x};
    my $lat_grid  = $z_xy->{y};
    my $unit_x    = 6.0 * $h_size;
    my $unit_y    = 6.0 * $h_size * $h_k;
    my $h_pos_x   = ( $lon_grid + $lat_grid /$h_k ) / $unit_x;
    my $h_pos_y   = ( $lat_grid - $h_k * $lon_grid ) / $unit_y;
    my $h_x_0     = floor( $h_pos_x );
    my $h_y_0     = floor( $h_pos_y );
    my $h_x_q     = $h_pos_x - $h_x_0;
    my $h_y_q     = $h_pos_y - $h_y_0;
    my $h_x       = round( $h_pos_x );
    my $h_y       = round( $h_pos_y );

    if ($h_y_q > - $h_x_q + 1.0) {
        if ( ( $h_y_q < 2.0 * $h_x_q ) && ( $h_y_q > 0.5 * $h_x_q ) ) {
            $h_x = $h_x_0 + 1.0;
            $h_y = $h_y_0 + 1.0;
        }
    } 
    elsif ( $h_y_q < - $h_x_q + 1.0 ) {
        if ( ( $h_y_q > ( 2.0 * $h_x_q ) - 1.0 ) && ( $h_y_q < ( 0.5 * $h_x_q ) + 0.5 ) ) {
            $h_x = $h_x_0;
            $h_y = $h_y_0;
        }
    }

    my $h_lat = ( $h_k * $h_x * $unit_x + $h_y * $unit_y ) / 2;
    my $h_lon = ( $h_lat - $h_y * $unit_y ) / $h_k;

    my $z_loc   = __xy2loc( $h_lon, $h_lat );
    my $z_loc_x = $z_loc->{lon};
    my $z_loc_y = $z_loc->{lat};

    if ( $h_base - $h_lon < $h_size ) {
        $z_loc_x  = 180;
        ( $h_x, $h_y ) = ( $h_y, $h_x );
    }

    my $h_code  = "";
    my @code3_x = ();
    my @code3_y = ();
    my $code3   = "";
    my $code9   = "";
    my $mod_x   = $h_x;
    my $mod_y   = $h_y;

    for ( my $i = 0; $i <= $level; $i++ ) {
        my $h_pow = 3.0 ** ( $level - $i );

        if ( $mod_x >= ceil( $h_pow/2.0 ) ) {
            $code3_x[$i] = 2.0;
            $mod_x -= $h_pow;
        } elsif ( $mod_x <= - ceil( $h_pow / 2.0 ) ) {
            $code3_x[$i] = 0.0;
            $mod_x += $h_pow;
        } else {
            $code3_x[$i] = 1.0;
        }

        if ( $mod_y >= ceil( $h_pow / 2.0 ) ) {
            $code3_y[$i] = 2.0;
            $mod_y -= $h_pow;
        } elsif ( $mod_y <= - ceil( $h_pow / 2.0 ) ) {
            $code3_y[$i] = 0.0;
            $mod_y += $h_pow;
        } else {
            $code3_y[$i] = 1.0;
        }
    }

    foreach my $i (0..$#code3_x) {
        $code3  .= $code3_x[$i] . $code3_y[$i];
        $code9  .= $calc->from_base($code3);
        $h_code .= $code9;
        $code9  = "";
        $code3  = "";
    }

    my $h_2   = substr( $h_code, 3 );
    my $h_1   = substr( $h_code, 0, 3 );
    my $h_a1  = floor( $h_1 / 30.0 );
    my $h_a2  = $h_1 % 30.0;
    $h_code   = ( substr( $h_key, $h_a1, 1 ) . substr( $h_key, $h_a2, 1 ) ) . $h_2;

    {
        code  => $h_code,
        x     => $h_x,
        y     => $h_y,
        lat   => $z_loc_y,
        lon   => $z_loc_x
    };
}

sub getZoneByCode {
    my $code    = shift;
    my $level   = length($code);
    my $h_size  = __setHexSize($level);
    my $unit_x  = 6.0 * $h_size;
    my $unit_y  = 6.0 * $h_size * $h_k;
    my $h_x     = 0.0;
    my $h_y     = 0.0;
    my $h_dec9  = (index($h_key, substr($code, 0, 1)) * 30.0 + index($h_key, substr($code, 1, 1))) . substr($code, 2);

    if ($h_dec9 =~ /^[15][^125][^125]/) {
        #my ($_h_dec9_0, $_h_dec9_1) = split /^./, $h_dec9;
        #if ($_h_dec9_0 eq 5) {
        #    $h_dec9 = 7 . $_h_dec9_1;
        #} elsif ($_h_dec9_0 eq 1) {
        #    $h_dec9 = 3 . $_h_dec9_1;
        #}
        if (substr($h_dec9, 0, 1) eq 5) {
            $h_dec9 = 7 . substr($h_dec9, 1);
        } elsif (substr($h_dec9, 0, 1) eq 1) {
            $h_dec9 = 3 . substr($h_dec9, 1);
        }
    }

    my $d9xlen = length($h_dec9);
    for (my $i = 0; $i < $level + 1 - $d9xlen; $i++) {
        $h_dec9 = 0 . $h_dec9;
        $d9xlen++;
    }

    my $h_dec3 = "";
    for (my $i = 0; $i < $d9xlen; $i++) {
        my $h_dec0 = "".$calc->to_base(substr($h_dec9, $i, 1));
        unless (defined $h_dec0) {
            $h_dec3 .= 00;
        } elsif (length($h_dec0) == 1) {
            $h_dec3 .= 0;
        }
        $h_dec3 .= $h_dec0;
    }

    my @h_decx = ();
    my @h_decy = ();

    for (my $i = 0; $i < length( $h_dec3 ) / 2; $i++) {
        $h_decx[$i] = substr( $h_dec3, $i * 2, 1 );
        $h_decy[$i] = substr( $h_dec3, $i * 2 + 1, 1 );
    }

    foreach my $i ( 0..$level ) {
        my $h_pow = 3 ** ($level - $i);
        if ( $h_decx[$i] eq 0 ) {
            $h_x -= $h_pow;
        } elsif ( $h_decx[$i] eq 2 ) {
            $h_x += $h_pow;
        }
        if ( $h_decy[$i] eq 0 ) {
            $h_y -= $h_pow;
        } elsif ( $h_decy[$i] eq 2 ) {
            $h_y += $h_pow;
        }
    }

    my $h_lat_y = ( $h_k * $h_x * $unit_x + $h_y * $unit_y ) / 2;
    my $h_lon_x = ( $h_lat_y - $h_y * $unit_y ) / $h_k;

    my $h_loc = __xy2loc( $h_lon_x, $h_lat_y );

    if ( $h_loc->{lon} > 180 ) {
        $h_loc->{lon} -= 360;
    } elsif ( $h_loc->{lon} < -180 ) {
        $h_loc->{lon} += 360;
    }

    {
        x     => $h_x,
        y     => $h_y,
        lat   => $h_loc->{lat},
        lon   => $h_loc->{lon},
        code  => $code
    };
}

sub __setHexSize {
  return $h_base / 3.0 ** ( $_[0] + 1 );
}

sub __loc2xy {
    my ($lon, $lat) = @_;
    my $x = $lon * $h_base / 180;
    my $y = log( tan( ( 90 + $lat ) * pi() / 360 ) ) / ( pi() / 180 );
    $y *= $h_base / 180;
    { x => $x, y => $y };
}

sub __xy2loc {
    my ( $x, $y ) = @_;
    my $lon = ( $x / $h_base ) * 180;
    my $lat = ( $y / $h_base ) * 180;
    $lat = 180 / pi() * ( 2 * atan( exp( $lat * pi() / 180 ) ) - pi() / 2 );
    { lon => $lon, lat => $lat };
}

1;
