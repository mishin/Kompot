package Kompot::Renderer::Mojo;

use strict;
use warnings;

use utf8;
use v5.12;

use Carp;
use DDP { output => 'stdout' };
use File::Spec::Functions 'catfile';
use Mojo::Template;

use base 'Kompot::Base';
use Kompot::Attributes;

has 'c';

sub init {
    my ($self, $c) = @_;

    return if not $c;
    $self->c($c);
    $self->register_default_helpers;
}

sub register_default_helpers {
    my $self = shift;

    # from Mojolicious::Plugin::DefaultHelpers
    for my $name (qw(layout title)) {
        $self->app->renderer->add_helper(
            $name => sub {
                my $self  = shift;
                my $stash = $self->stash;

                $stash->{$name} = shift if @_;
                $self->stash(@_) if @_;

                return $stash->{$name};
            }
        );
    }
}

sub render {
    my ($self, $name) = @_;

    return if not $name;
    $name = "$name.html.ep";

#    my $tmpl = $self->_template_path($name) or return;
#    my $out = $self->_process($tmpl) or return;
    my $out = $self->_process($name) or return;

    while (my $extends = $self->_extends($self)) {
        $self->stash(content => $out);
#        $tmpl = $self->_template_path($extends) or return;
#        $out = $self->_process($tmpl) or return;
        $out = $self->_process($name) or return;
    }

    return $out;
}

sub _template_path {
    my ($self, $name) = @_;

    my $paths = $self->app->renderer->paths;
    for my $path (@$paths) {
        my $file = catfile($path, split('/', $name));
        return $file if -r $file;
    }

#    carp "Can't find `$name` in paths.";
    return;
}

sub _extends {
    my $self = shift;

    my $stash = $self->c->stash;
    my $layout = delete $stash->{layout};

    $stash->{extends} ||= join('/', 'layouts', $layout) if $layout;

    return delete $stash->{extends};
}

sub _process {
    my ($self, $name) = @_;

    my $c = $self->c;
    my $stash   = $c->stash;
    my $helpers = $self->app->renderer->helpers;

    my $prepend = q/
my $self = shift;
use Scalar::Util 'weaken';
weaken $self;
no strict 'refs';
no warnings 'redefine';
my $_H = $self->app->renderer->helpers;
/;

    for my $name (keys %$helpers) {
        next if $name !~ /^[a-z]\w*$/i;
        $prepend .= "sub $name; *$name = sub {\$_H->{'$name'}->(\$self, \@_)};";
    }

    $prepend .= 'use strict; my $_S = $self->stash;';

    for my $var (keys %$stash) {
        next if $var !~ /^[a-z]\w*$/i;
        $prepend .= "my \$$var = \$_S->{'$var'};";
    }

    $prepend =~ s/\R//gs;

    my $mt = Mojo::Template->new(encoding => 'UTF-8');
    $mt->prepend($prepend);

    my $out;
    
    if (my $file = $self->_template_path($name)) {
        $out = $mt->name("FILE $file")->render_file($file, $c);
    }
    elsif (my $data = $self->app->renderer->get_data_template($name)) {
        $out = $mt->name("DATA $name")->render($data, $c);
    }
    else {
        carp "Can not find template `$name`!";
        return;
    }

    if (ref $out) {
        croak 'Render error: ' . $out->to_string;
    }

    return $out;
}

1;

__END__
