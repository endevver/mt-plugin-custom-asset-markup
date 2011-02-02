### CustomAssetMarkup plugin
# AUTHOR:   Jay Allen, Textura Design
# See README.txt in this package for more details
# $Id: CustomAssetMarkup.pm 37 2008-08-05 20:20:42Z jayallen $

package CustomAssetMarkup;

use strict;
use Data::Dumper;

use File::Spec;
use MT::Util qw(format_ts   relative_date );
# use MT::Log::Log4perl qw(l4mtdump);
# our $logger = MT::Log::Log4perl->new();

sub as_html {
    my $plugin      = shift;
    my $orig_method = shift;
    my $asset       = shift;
    my ($param) = @_;
    # $logger->trace();

    # $logger->debug('@_: ', l4mtdump(\@_));

    my $tmpl = $plugin->runner('template', $param->{blog_id});
    $tmpl->param($param);
    
    my $ctx = $tmpl->context;
    local $ctx->{__stash}{asset} = $asset;

    my %cond;
    my $html = $tmpl->build( $ctx, \%cond );
    # $logger->debug('HTML: ', $html);
    return $html;

}

sub template {
    my $plugin = shift;
    my $blog_id = shift;

    require MT::Template;
    my ($tmpl, %args);

    my $name = 'Custom Asset Insertion Markup';
    my $identifier = 'custom_asset_markup';

    # In order to allow blog-level overrides and ensure that we load an
    # existing template we attempt to load the template in three
    # different ways:
    #   1. Load from the asset's blog by template name
    #   2. Load from the system-level global templates by identifier
    #   3. Load from the system-level global templates by name
    my @attempts = (
        { blog_id => 0, identifier => $identifier },
        { blog_id => 0, name => $name,  }
    );
    # If blog is in context, try loading from the blog by name first.
    $blog_id and unshift(@attempts, { blog_id => $blog_id,  name => $name });
    
    # Attempt to load the template
    foreach my $args (@attempts) {
        $tmpl = MT::Template->load($args);
        last if $tmpl;
    }

    # If none of those worked, instantiate a new version of the
    # template as a global template module.
    unless ($tmpl) {
        
        # Load the template source from this plugin envelope's tmpl dir
        my $filename = $identifier . '.mtml';
        # $logger->debug("Trying to load file $filename");    
        $tmpl = $plugin->load_tmpl($filename)
            or die sprintf('Could not locate default custom '
                    .'asset markup template %s', $filename);            

        # Grab the source of the template
        my $text = $tmpl->text;
        # $logger->debug('tmpl->text: ', $text);

        # Create a new global template module with the source
        $tmpl = MT::Template->new;
        $tmpl->name($name);
        $tmpl->text($text);
        $tmpl->type('custom');
        $tmpl->blog_id(0);
        $tmpl->identifier($identifier);
        $tmpl->save
          or die "Could not save custom asset markup global template: "
                .$tmpl->errstr;
    }
    $tmpl;
}

sub text {
    return <<EOD;
    AssetID = <mt:AssetID>
    AssetFileName = <mt:AssetFileName>
    AssetLabel = <mt:AssetLabel>
    AssetURL = <mt:AssetURL>
    AssetType = <mt:AssetType>
    AssetMimeType = <mt:AssetMimeType>
    AssetFilePath = <mt:AssetFilePath>
    AssetDateAdded = <mt:AssetDateAdded>
    AssetAddedBy = <mt:AssetAddedBy>
    AssetProperty = <mt:AssetProperty>
    AssetFileExt = <mt:AssetFileExt>
    AssetThumbnailURL = <mt:AssetThumbnailURL>
    AssetLink = <mt:AssetLink>
    AssetThumbnailLink = <mt:AssetThumbnailLink>
    AssetDescription = <mt:AssetDescription>

EOD
}

1;

__END__


