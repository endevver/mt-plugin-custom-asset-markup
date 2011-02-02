package MT::Plugin::CustomAssetMarkup;
# A plugin for Movable Type
# See README.txt in this package for more details
# Copyright 2007, All rights reserved
# $Id: CustomAssetMarkup.pl 37 2008-08-05 20:20:42Z jayallen $
use strict; use 5.006; use warnings; use Data::Dumper;

use MT 4.0;
use base 'MT::Plugin';

# Public version number
our $VERSION = '0.6.1';

# Development revision number
our $Revision = ('$Revision: 37 $ ' =~ /(\d+)/);

our ($plugin, $PLUGIN_MODULE, $PLUGIN_KEY);
MT->add_plugin($plugin = __PACKAGE__->new({
    name        => 'Custom Asset Markup',
    version     => $VERSION.'-beta',
    key         => plugin_key(),
    author_name => 'Jay Allen, Endevver Consulting',
    author_link => 'http://endevver.com',
    description =>
        'Provides for the ability to customize the insertion markup for all '
        .'asset types through a system template.',
}));

# use vars qw($logger);
# use MT::Log::Log4perl qw(l4mtdump);
# $logger = MT::Log::Log4perl->new();

{
    no warnings 'redefine';
    no strict 'refs';

    require MT::Asset;
    if (my $oldsub = MT::Asset->can('as_html')) {        
        *MT::Asset::as_html        = sub { runner( 'as_html', $oldsub, @_ ) };
    }

    require MT::Asset::Image;
    if (my $oldsub = MT::Asset::Image->can('as_html')) {        
        *MT::Asset::Image::as_html = sub { runner( 'as_html', $oldsub, @_ ) };
    }
}

sub init_request {
    my $plugin = shift;
    $plugin->SUPER::init_request(@_);
    my $app = MT->instance() or return;

    # Initialize template upon viewing global template screen, if non-existent
    return unless ! $app->param('blog_id')
            and (   $app->mode eq 'list_template'
                 or $app->mode eq 'list' and $app->param('_type') eq 'template');
    my $tmpl = $plugin->runner('template');
}

sub plugin_module   {
    ($PLUGIN_MODULE = __PACKAGE__) =~ s/^MT::Plugin:://;
    return $PLUGIN_MODULE; }

sub plugin_key      {
    ($PLUGIN_KEY = lc(plugin_module())) =~ s/:+/-/g;  return $PLUGIN_KEY; }

sub current_blog {
    my $self = shift;
    my $app = MT->instance or return;
    return $app->blog               ? $app->blog
         : $app->param('blog_id')   ? MT::Blog->load($app->param('blog_id'))
         : undef;
}

sub runner {
    shift if ref($_[0]) eq ref($plugin);
    my $method = shift;
    my $module = plugin_module();
    eval "require $module;";
    if ($@) { print STDERR $@; $@ = undef; return 1; }
    my $method_ref = $PLUGIN_MODULE->can($method);
    return $method_ref->($plugin, @_) if $method_ref;
    die MT->translate(
        'Failed to find '.$PLUGIN_MODULE.'::[_1]', $method);
}


1;

