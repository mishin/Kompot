package Kompot::App;

use strict;
use warnings;

use utf8;
use v5.12;

use Carp;
use DDP { output => 'stdout' };

use base 'Kompot::Base';
use Kompot::Attributes;
use Kompot::Config;
use Kompot::Handler;
use Kompot::Renderer;
use Kompot::Routes;
use Kompot::Session;

has 'name' => 'Kompot';
has 'secret';

sub init { 
    my $self = shift;
    $self->name('Kompot_' . $Kompot::VERSION);
}

sub request { 
    my $self = shift;
    state $request;
    $request = Kompot::Request->new(@_) if scalar @_;
    return $request;
}

sub renderer { state $renderer ||= Kompot::Renderer->new }
sub render   { goto &renderer }

sub routes { state $route ||= Kompot::Routes->new }
sub route  { goto &routes }

sub conf { state $conf ||= Kompot::Config->new }

#
# Main function
#
sub run {
    my $self = shift;

    if (not $self->secret) {
        croak 'Define `secret` before start application!';
    }

    my $handler = Kompot::Handler->new;
#p($handler);

    my $response = $handler->start;
#p($response);

    return $response;
}

1;

__END__
