package Kompot::Renderer::Xslate;

use strict;
use warnings;

use utf8;
use v5.12;

use Carp;
use Text::Xslate;

use base 'Kompot::Base';

__PACKAGE__->attr(c => undef);

sub init {
    my ($self, $c) = @_;

    return if not $c;
    $self->c($c);
    $self->register_default_helpers;
}

sub register_default_helpers {}

sub render {
    my ($self, $name, %options) = @_;

    my $c = $self->c;
    my $r = $self->app->renderer;

    my $xslate =
        Text::Xslate->new({
#            cache_dir => $cache_dir, # TODO
            path      => $r->paths,
            function  => $r->helpers,
            %options,
        });

    my $out;
    eval { $out = $xslate->render($name, $c->stash); };
    if ($@) {
        carp $@;
        $out = '';
    }

    return $out;
}

1;

__END__
