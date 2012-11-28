package Kompot::Renderer::Text;

use v5.12;

use strict;
use warnings;

use utf8;

use base 'Kompot::Base';

use Kompot::Response;

sub render {
    my $self = shift;

    my $p = { @_ };

    my $pp    = delete( $p->{params} );
    my $text  = delete( $p->{text} );


    foreach my $ph ( keys(%$pp) ) {
        $text =~ s/<%\s?$ph\s?%>/$pp->{$ph}/g;
    }


    return
        Kompot::Response->new(
            content_type => $pp->{'content-type'} || 'text/plain',
            content      => $text,
        );
}


1;

__END__