#!/usr/bin/perl

# File: cvit.pl

# Use: Generates a images in a range of sizes displaying one or more chromosomes
#      and ranges or positions on those chromosomes, indicated with bars or dots
#      and optional labels. Also  produces a GFF file describing all data and
#      image attributes that could be used by another application.

# Data in: config file(s) and one GFF file specifying ranges and positions. Ranges
#          and positions would both be in one file.
#          Supports GFF version 2 & 3.

# Data out: Images in a range of sizes and a GFF file describing the images and
#           all ranges and positions represented in the images.

# http://www.sequenceontology.org/gff3.shtml

# Types of GFF records interpreted: 
#    chromosome - defines a chromosome (or piece of chromosome)
#    marker-hit - a hit on a marker, displayed as a bar
#    marker     - defines a marker, displayed as a dot
#    clone      - names and gives the range of a clone, displayed by horizontal
#                 lines directly on the chromosome
#    hit        - a specialized position, probably a blast hit, displayed as a dot
#    centromere - locates a centromere, displayed by wider gray bar directly on
#                 chromosome.
#    measure    - attaches a measure of importance to a range. Could be e-value,
#                 hits per location, et cetera. Value of measure is in attributes,
#                 value=
# otherwise:
#    an undefined position is displayed as a dot
#    and undefined range is displayed as a bar to right of chromosome.
#
# Documentation:
#    http://search.cpan.org/dist/GD/
#    http://search.cpan.org/~tcaine/GD-Arrow-0.01/lib/GD/Arrow.pm
#    http://search.cpan.org/~wadg/Config-IniFiles-2.38/IniFiles.pm

my $VERSION = "b1.2";

use strict;
use warnings;
use IO::File;
use POSIX qw(tmpnam);
use Getopt::Std;
use Config::IniFiles;

use Data::Dumper;  # for debugging

# images will be saved as pngs
my $image_format = "png";

my $debug = 1;                        # set to 0 to turn off debugging
my $config_file = "config/cvit.ini";  # default config file


### Get command line information
my $title         = '';
my $out_filename  = undef;
my $reverse_ruler = 0;
my %options = ();
getopts("c:o:rt:", \%options);
if (defined($options{'c'})) { $config_file       = $options{'c'}; }
if (defined($options{'o'})) { $out_filename      = $options{'o'}; }
if (defined($options{'r'})) { $reverse_ruler     = 1; }
if (defined($options{'t'})) { $title             = $options{'t'}; }
#######


### verify that we have enough information to run the script:
my $warning = <<EOF;

  Usage for the CVIT script:
    perl cvit.pl [opt] gff-file-in [gff-file-in]*

    -c <file>           alternative config file (default: config/cvit.ini)
    -o <string>         base filename (default: unique id)
    -r                  reverse ruler
    -t <string>         title for image
    
    *Multiple gff input files make possible various layers: chromosomes, centromeres, borders, etc.
    For example (ignore line wraps):
    perl cvit.pl -c config/cvit_histogram.ini -v histogram -o MtChrXxMtLjTEs 
         data/MtChrs.gff3 data/BACborders.gff3 data/MtCentromeres.gff3 
         /web/medicago/htdocs/genome/upload/MtChrXxMtLjTEs.gff
         
    The GFF data MUST contain some sequence records of type 'chromosome' or 
    there will be no way to draw the picture.
EOF

if (!($ARGV[0]) && scalar(keys(%options)) == 0) { die $warning }
#######


### Get config information:
if (!(-e $config_file)) {
  die "\nERROR: config file ($config_file) not found\n\n";
}
my $ini = new Config::IniFiles( -file => $config_file);
die "\nERROR: Couldn't parse $config_file!\n\n" if (!$ini);
#######


### Set debugging/logging information:
my $logfile   = $ini->val('general', 'logfile');
my $errorfile = $ini->val('general', 'errorfile');

#require "pkgs/errorlog.pm";
#my $dbg = ErrorLog->new();
#$dbg->createLog($debug, $logfile, $errorfile, "f"); # s=stdout, b=browser, f=log file
#$dbg->logMessage("\n\n\n-----------------START----------------\n");
#my $error; #always enabled
#######


### Create unique base name if none given
if (!$out_filename || length($out_filename) == 0) {
  $out_filename = get_unique_ID(10);
}
#######


#### get user-defined sequence types; indicated by 'feature' attribute
my %custom_types;
foreach my $section ($ini->Sections()) {
  if ($ini->val($section, 'feature')) {
    my $feature_name = $ini->val($section, 'feature');
    $custom_types{$feature_name} = $section;
  }
}#each section
#######


### Read and parse gff input file(s) into tables
my @chromosomes; # array of chromosomes (reference, or backbone sequence) in GFF
my @ranges;      # array of all ranges found in GFF data
my @positions;   # array of all positions found in GFF data
my @borders;     # array of all borders (e.g. of BACs) found in GFF data
my @markers;     # array of all markers found in GFF data
my @centromeres; # array of all centromeres found in GFF data
my @measures;    # array of all measure-value records in GFF data

foreach my $gfffile (@ARGV) {
  $dbg->logMessage("\nRead gff file $gfffile\n");
  if (!(-e $gfffile)) {
    my $msg = "\nWARNING:unable to find GFF file $gfffile\n\n";
    print $msg;
    $dbg->reportError($msg);
  }
  
  read_gff($gfffile, $reverse_ruler);
  
  if ($error && length($error) > 0) {  # report file error, if any
    $dbg->reportError("$error\n");
    $error = "";
  }
}

if ((scalar @chromosomes) == 0) {
  my $msg = "No chromosomes were found. CViT can't continue";
  print $msg;
  $dbg->reportError($msg);
  exit;
}
#######


### Create and write out a CViT image and a legend
if (int($ini->val('general', 'slice', 0)) == 1) {
  print "\nSLICED-UP CVIT IMAGES\n";
  draw_sliced_records($out_filename, \@chromosomes, \@centromeres, \@borders, 
                      \@ranges, \@positions, \@markers, \@measures, [], 1);
}
else {
  print "\nCVIT IMAGE\n";
  draw_all_records($out_filename, \@chromosomes, \@centromeres, \@borders, 
                   \@ranges, \@positions, \@markers, \@measures, [], 1);
}

# Draw a separate legend image
print "\nLEGEND\n";
draw_legend();
#######



###############################################################################
################################### subs ######################################

###################
# draw_all_records()

sub draw_all_records {
  my ($out_filename, $chromosomes_ref, $centromeres_ref, $borders_ref, 
      $ranges_ref, $positions_ref, $markers_ref, $measures_ref, $special_ref,
      $write_coords) = @_;
#print "draw_all_records()\n";
#print "chromosomes_ref:\n" . Dumper($chromosomes_ref);

  require 'pkgs/ColorManager.pm';
  my $clr_mgr = new ColorManager('rgb.txt');

  require 'pkgs/FontManager.pm';
  my $font_mgr = new FontManager();
  
  require 'pkgs/CvitImage.pm';
  my $cvit_image = new CvitImage($clr_mgr, $font_mgr, $ini, $dbg);
  if ($reverse_ruler == 1) {
    $cvit_image->reverse_ruler();
  }
  $cvit_image->create_image($chromosomes_ref);
  
  # Check if ruler will run backwards (e.g. north arm of cytogenetic chromosome)
  my (@centromeres, @borders, @ranges, @positions, @markers, @measures);
  if ($reverse_ruler == 1) {
    @centromeres = reverse_coords($cvit_image, $centromeres_ref);
    @borders     = reverse_coords($cvit_image, $borders_ref);
    @ranges      = reverse_coords($cvit_image, $ranges_ref);
    @positions   = reverse_coords($cvit_image, $positions_ref);
    @markers     = reverse_coords($cvit_image, $markers_ref);
    @measures    = reverse_coords($cvit_image, $measures_ref);
  }
  else {
    @centromeres = @$centromeres_ref;
    @borders     = @$borders_ref;
    @ranges      = @$ranges_ref;
    @positions   = @$positions_ref;
    @markers     = @$markers_ref;
    @measures    = @$measures_ref;
  }
  
  # Sort ranges by coordinates
  if (scalar @ranges > 1) {
    # order ranges by chromosome and start position
    my @unsorted_ranges = @ranges;
    @ranges = sort {
                   if ($a->[0] gt $b->[0]) { return 1; }
                   elsif ($a->[0] lt $b->[0]) { return -1; }
                   else {
                     if ($a->[4] > $b->[4]) { return 1; }
                     elsif ($a->[4] < $b->[4]) { return -1; }
                     else { return 0; }
                   }
                 } @unsorted_ranges;
  }#sort ranges

  require 'pkgs/GlyphDrawer.pm';
#print "$cvit_image, $clr_mgr, $font_mgr, $ini, $dbg\n";
  my $glyph_drawer = new GlyphDrawer($cvit_image, $clr_mgr, $font_mgr, $ini, $dbg);
  
  # draw features on chromosomes
  $glyph_drawer->draw_glyph(\@centromeres, 'centromere');
  $glyph_drawer->draw_glyph(\@borders, 'border');
  $glyph_drawer->draw_glyph(\@ranges, 'range');
  $glyph_drawer->draw_glyph(\@positions, 'position');
  $glyph_drawer->draw_glyph(\@markers, 'marker');
  $glyph_drawer->draw_glyph(\@measures, 'measure');
  
  # print png image
  my $out_image_file = "$out_filename.$image_format";
  print_image($cvit_image->get_image(), $out_image_file);
  
  if ($write_coords == 1) {
    # print feature locations file
    #      format: name => chromosome,start,end,x1,y1,x2,y2
    my $glyph_coords_ref = $glyph_drawer->{feature_coords};
#print "\nglyph_coords_ref ($glyph_coords_ref)\n";
#print Dumper($glyph_coords_ref);
    my $chrom_coords_ref = $cvit_image->{feature_coords};
#TODO: wrong data types passed into print_coords
#print "glyphs:\n" . Dumper($glyph_coords_ref);
#print "chroms:\n" . Dumper($chrom_coords_ref);
#    my @feature_coords = (@$glyph_coords_ref, 
#                          @$chrom_coords_ref);
#    
#    my $out_coords_file = "$out_filename.coords.csv";
#    print_coords(\@feature_coords, $out_coords_file);
  }#write out coords
}#draw_all_records


sub draw_legend {
  # Get pixels per unit and units per pixel
  my $scale_factor  = $ini->val('general', 'scale_factor'); # pixels
  my $units_per_pixel = 1 / $scale_factor;         # units
  
  #TODO: make this an option?
  # Each glyph will take this much vertical space in pixels:
  my $glyph_height = 25;
   
  # Each glyph will take this much vertical space in units:
  my $glyph_height_units = $units_per_pixel * $glyph_height;

  # Create gff records for each type of glyph
  my (@legend_positions, @legend_ranges, @legend_borders, @legend_markers,
      @legend_centromeres, @legend_measures);
  my $start = $glyph_height_units; # units
  $start = get_legend_glyphs('position', $start, $glyph_height_units, 
                             \@positions, \@legend_positions);
  $start = get_legend_glyphs('range', $start, $glyph_height_units, 
                             \@ranges, \@legend_ranges);
  $start = get_legend_glyphs('border', $start, $glyph_height_units, 
                             \@borders, \@legend_borders);
  $start = get_legend_glyphs('marker', $start, $glyph_height_units, 
                             \@markers, \@legend_markers);
  $start = get_legend_glyphs('measure', $start, $glyph_height_units, 
                             \@measures, \@legend_measures);
  $start = get_legend_glyphs('centromere', $start, $glyph_height_units, 
                             \@centromeres, \@legend_centromeres);

  my $num_glyphs = scalar @legend_positions 
                   + scalar @legend_ranges 
                   + scalar @legend_borders 
                   + scalar @legend_markers 
                   + scalar @legend_centromeres 
                   + scalar @legend_measures;

  # Create a chromosome record for the legend records
  my $chrstart    = 0;
  my $chrend      = $chrstart + $glyph_height_units*($num_glyphs+1);
  my $chromosome  = 'Chr';
  my @chromosomes = [$chromosome, '.', '.', $chrstart, $chrend, 
                         '.', '.', '.', "ID=$chromosome"];

  # Some drawing attributes will need to be altered
  $ini->setval('general',  'display_ruler', 0);
  $ini->setval('general',  'image_padding', 35);
  $ini->setval('general',  'chrom_x_start', 0);
  $ini->setval('general',  'title',         'Legend');
  $ini->setval('general',  'title_height',  10);
  $ini->setval('general',  'chrom_spacing', 0);
  $ini->setval('general',  'ruler_min',     0);
  $ini->setval('general',  'ruler_max',     0);
  $ini->setval('position', 'draw_label',    1);
  $ini->setval('range',    'draw_label',    1);
  $ini->setval('border',   'draw_label',    1);
  $ini->setval('marker',   'draw_label',    1);
  $ini->setval('centromere', 'draw_label',  1);
  $ini->setval('measure',  'draw_label',    0);
  
  # Accomodate labels to the left and right of the chromosome
  $ini->setval('general',  'chrom_padding_left', 
               labelsLeftWidth(\@legend_centromeres, \@legend_borders, 
                               \@legend_ranges, \@legend_positions, 
                               \@legend_markers, \@legend_measures));
  $ini->setval('general',  'chrom_padding_right', 
               labelsRightWidth(\@legend_centromeres, \@legend_borders, 
                                \@legend_ranges, \@legend_positions, 
                                \@legend_markers, \@legend_measures));

  draw_all_records("$out_filename.legend", 
                   \@chromosomes, \@legend_centromeres, \@legend_borders, 
                   \@legend_ranges, \@legend_positions, \@legend_markers, 
                   \@legend_measures, [], 0);
}#draw_legend


#######################
# draw_sliced_records()
# Cut up the image in slices. Because GD doesn't handle memory well and can't
# handle large images.

sub draw_sliced_records {
  my ($out_filename, $chromosomes_ref, $centromeres_ref, $borders_ref, 
      $ranges_ref, $positions_ref, $markers_ref, $measures_ref, $special_ref,
      $write_coords) = @_;

  @chromosomes = @$chromosomes_ref;
  @centromeres = @$centromeres_ref;
  @borders     = @$borders_ref;
  @ranges      = @$ranges_ref;
  @positions   = @$positions_ref;
  @markers     = @$markers_ref;
  @measures    = @$measures_ref;
#print "There are " . scalar @centromeres . " centromeres, ";
#print scalar @borders . " borders, ";
#print scalar @ranges . " ranges, ";
#print scalar @positions . " positions, ";
#print scalar @markers . " markers, ";
#print scalar @measures . " measures\n";

  my $file_count = 1;
  my $slice_size = $ini->val('general', 'slice_size', 100000);
  
  # put all of these in an array
  my %all_glyphs = ('centromere' => $centromeres_ref, 
                    'border'     => $borders_ref, 
                    'range'      => $ranges_ref, 
                    'position'   => $positions_ref, 
                    'marker'     => $markers_ref, 
                    'measure'    => $measures_ref);
  my %all_indices = ('centromere' => 0,
                     'border'     => 0, 
                     'range'      => 0, 
                     'position'   => 0, 
                     'marker'     => 0, 
                     'measure'     => 0);
  # need glyphs in order; keys won't list glyphs in the same order as above
  my @glyphs = ('centromere', 'border', 'range', 
                'position', 'marker', 'measure');

  # sort everything
  my @unsorted_chromosomes = @chromosomes;
  @chromosomes = sort {
              if ($a->[0] gt $b->[0]) { return 1; }
              elsif ($a->[0] lt $b->[0]) { return -1; }
              else {
                if ($a->[4] > $b->[4]) { return 1; }
                elsif ($a->[4] < $b->[4]) { return -1; }
                else { return 0; }
              }
            } @unsorted_chromosomes;
  
  foreach my $glyph_type (@glyphs) {
    my @glyphs = @{$all_glyphs{$glyph_type}};
    if (scalar @glyphs > 1) {
#print "sort " . scalar @glyphs . " $glyph_type glyphs\n";
      my @unsorted_glyphs = @glyphs;
      @glyphs = sort {
                  if ($a->[0] gt $b->[0]) { return 1; }
                  elsif ($a->[0] lt $b->[0]) { return -1; }
                  else {
                    if ($a->[4] > $b->[4]) { return 1; }
                    elsif ($a->[4] < $b->[4]) { return -1; }
                    else { return 0; }
                  }
                } @unsorted_glyphs;
    }
  }#each array of glyphs

#print "split up " . (scalar @chromosomes) . " centromeres into $slice_size-sized pieces.\n";
  foreach my $chromosome (@chromosomes) {
    my ($seqid, $source, $type, $start, $end, $score, $strand, $phase, 
        $attributes) = @$chromosome;
#print "chromosome record: $seqid, $source, $type, $start, $end, $score, $strand, $phase, $attributes\n";
    my $slice_count = int(($end - $start) / $slice_size + 1);
#print "Cut $seqid into $slice_count sections.\n";

    for (my $i=0; $i<$slice_count; $i++) {
      # Make a "chromosome" record
      my $new_start = $start + ($i*$slice_size);
      my $new_end = (($i+1)*$slice_size > $end) 
                      ? $end : $start+($i+1)*$slice_size;
      $ini->setval('general', 'ruler_min', $new_start);
      my @sliced_glyphs;
      push @sliced_glyphs, [[($seqid, $source, $type, $new_start, $new_end, 
                              $score, $strand, $phase, $attributes)]];

      # Pull out the glyphs that fit inside this slice
      foreach my $glyph_type (@glyphs) {
        my @glyphs = @{$all_glyphs{$glyph_type}};
        my $glyph_index = $all_indices{$glyph_type};
#if (scalar @glyphs > 0) {print "Current glyph index for $glyph_type: $glyph_index. Looking at chr " . $glyphs[0][0] . "\n";}
        my @new_glyphs;
        while ($glyph_index < (scalar @glyphs) && $glyphs[0][4] < $new_end) {
          push @new_glyphs, shift @glyphs;
          $glyph_index++;
        }
        $all_indices{$glyph_type} = $glyph_index;
        push @sliced_glyphs, \@new_glyphs;
      }#each glyph type
#print "Draw " . scalar @sliced_glyphs . " types of glyphs.\n";
#my $count = 0;
#foreach my $array_ref (@sliced_glyphs) {
#  print "$count: " . scalar @$array_ref . " records.\n";
#  $count++;
#}

#print "Write slice for $seqid.\n";
#print Dumper(@sliced_glyphs);
#print "\n\n\n\n";
      #chromosomes, centromeres, borders, ranges, positions, markers, measures
      draw_all_records("$out_filename$file_count.$seqid", @sliced_glyphs, [], 1);

      $file_count++;
last;
    }#each splice
last;
  }#each chromosome
}#draw_sliced_records


##################
# get_attributes()
# Split an attribute string into key=value pairs.

sub get_attributes {
   my $attrs = $_[0];
   my @attribute_list = split /;/, $attrs;
   return map { lc(attr_key($_)) => attr_val($_) } @attribute_list;
}#get_attributes

sub attr_key {
  my @parts = split(/=/, $_);
  return $parts[0];
}
sub attr_val {
  my @parts = split(/=/, $_);
  return $parts[1];
}


#####################
# get_legend_glyphs()

sub get_legend_glyphs {
  my ($glyph, $start, $glyph_height_units, $records_ref, 
      $legend_records_ref) = @_;
  
  my @records = @$records_ref;
  my @legend_records = @$legend_records_ref;
  
   if (scalar @records == 0) {
      return $start;
   }
   
   # Height of this glyph
   my $height;
   if ($glyph eq 'position') {
     $height = 0;
   }
   elsif ($glyph eq 'measure') {
     if ($ini->val('measure', 'display') eq 'heat') {
       $height = $glyph_height_units;
     }
     else {
       $height = $glyph_height_units/2;
     }
   }
   else {
     $height = $glyph_height_units/2;
   }
   
   #TODO: this could be an ini file option
   # A generic chromosome name
   my $chromosome = 'Chr';
   
   # This will keep track of which variants of this glyph have been handled
   my %types;
   
   foreach my $record (@records) {
      my ($d1, $source, $type, $d2, $d3, $d4, $d5, $d6, $attrs) = @$record;
      my %attributes = get_attributes($attrs);
      my $class_name = ($attributes{'class'}) ? $attributes{'class'} : undef;
      my $color_index = 0;
      my $color_name;

      if ($glyph eq 'measure' && !$types{$glyph}) {
        $types{$glyph} = 1;
        $types{"$source:$type"} = 1; # only one type of measure allowed
        
        my $value_type = _trim($ini->val('measure', 'value_type'));
        if (_trim($ini->val('measure', 'display')) eq 'heat') {
          # Get max if value_type is 'score_col'
          my $max_score;
          if ($value_type eq 'score_col') {
            # assumed to be an e-value
            my $max = get_max_score(\@measures);
            $max_score = sprintf("%.2e", $max);
          }
          else {
            $max_score = 0; # will be calculated elsewhere
          }

          push @$legend_records_ref, 
               [$chromosome, '.', 'heatmap_legend', $start, $start+$height, 
                $max_score, '.', '.', "ID=$source $type;"];
        }
        else {
          push @$legend_records_ref, 
               [$chromosome, '.', 'measure', $start, $start+$height, 
                '0', '.', '.', "ID=$source $type value;"];
        }
        $start += $glyph_height_units;
      }#measure
      
      if ($class_name && $class_name ne '') {
         if (!$types{$class_name}) {
            $types{$class_name} = 1;
            $color_index++;
            push @$legend_records_ref, 
                 [$chromosome, $source, $type, $start, $start+$height, 
                  '.', '.', '.', "name=$class_name;class=$class_name"];
            $start += $glyph_height_units;
         }#haven't seen this class yet
      }#record has a class
        
      elsif (!$types{"$source:$type"} && $custom_types{"$source:$type"}) {
         $color_name = $ini->val($custom_types{"$source:$type"}, 
                                   'color', 
                                   $ini->val($glyph, 'color'));
         $types{"$source:$type"} = 1;
         push @$legend_records_ref, 
              [$chromosome, $source, $type, $start, $start+$height, 
               '.', '.', '.', "name=$source $type"];
         $start += $glyph_height_units;
      }#haven't seen this source&type yet
      
      elsif (lc($type) eq 'centromere' && !$types{'centromere'}) {
         $color_name = $ini->val('centromere', 'color');
         $types{'centromere'} = 1;
         push @$legend_records_ref, 
              [$chromosome, $source, $type, $start, $start+$height, 
               '.', '.', '.', "ID=centromere"];
         $start += $glyph_height_units;
      }#centromere
      
      elsif (scalar @$legend_records_ref == 0 && !$types{$glyph}) {
        # only one type for this glyph
        $types{$glyph} = 1;
        # create one fake record
        push @$legend_records_ref,
             [$chromosome, '.', '.', $start, $start+$height, 
              '.', '.', '.', "name=$glyph"];
        $start += $glyph_height_units;
      }#everything else
   }#each record

   return $start;
}#get_legend_glyphs


#################
# get_max_score()

sub get_max_score {
  my $records_ref = $_[0];
  my @records = @$records_ref;
  my $max = 0;
  foreach my $record (@records) {
    my ($d1, $d2, $d3, $d4, $d5, $score, $d6, $d7, $d8) = @$record;
    if ($score > $max) {
      $max = $score;
    }
  }
  
  return $max;
}#get_max_score


#################
# get_unique_ID()
# Generate a unique string of the requested length.
sub get_unique_ID {
  my $length = $_[0];
  my $unique_id = "";
  
  for(my $i=0 ; $i<$length ;) {
    my $ch = chr(int(rand(127)));
    if( $ch =~ /[a-zA-Z0-9]/) {
      $unique_id .=$ch;
      $i++;
    }
  }
  return $unique_id;
}#get_unique_ID


############
# in_array()

sub in_array {
   my $string = shift @_;
   return (grep $_ eq $string, @_);
}#in_array


#TODO: this should measure max width of left labels
sub labelsLeftWidth {
  my ($centromeres_ref, $borders_ref, $ranges_ref, $positions_ref, $markers_ref, 
      $measures_ref) = @_;
  
  my $has_centromeres = (scalar @$centromeres_ref > 0);
  my $has_borders     = (scalar @$borders_ref > 0);
  my $has_ranges      = (scalar @$ranges_ref > 0);
  my $has_positions   = (scalar @$positions_ref > 0);
  my $has_markers     = (scalar @$markers_ref > 0);
  my $has_measures    = (scalar @$measures_ref > 0);

#print "has_centromeres: $has_centromeres, ";
#print "draw_label: " . $ini->val('centromere', 'draw_label');
#print "offset: " . $ini->val('centromere', 'label_offset') , "\n";

  if (($has_centromeres && $ini->val('centromere', 'draw_label') == 1 
        && $ini->val('centromere', 'label_offset') < 0)
      || ($has_borders && $ini->val('border', 'draw_label') == 1 
        && $ini->val('border', 'label_offset') < 0)
      || ($has_ranges && $ini->val('range', 'draw_label') == 1 
        && $ini->val('range', 'label_offset') < 0)
      || ($has_positions && $ini->val('position', 'draw_label') == 1 
        && $ini->val('position', 'label_offset') < 0)
      || ($has_markers && $ini->val('marker', 'draw_label') == 1 
        && $ini->val('marker', 'label_offset') < 0)
      || ($has_measures && $ini->val('measure', 'draw_label') == 1 
        && $ini->val('measure', 'label_offset') < 0)) {
    return 50;
  }
  else {
    return 0;
  }
}#labelsLeftWidth


#TODO: this should measure max width of right labels
sub labelsRightWidth {
  my ($centromeres_ref, $borders_ref, $ranges_ref, $positions_ref, $markers_ref, 
      $measures_ref) = @_;
  
  my $has_centromeres = (scalar @$centromeres_ref > 0);
  my $has_borders     = (scalar @$borders_ref > 0);
  my $has_ranges      = (scalar @$ranges_ref > 0);
  my $has_positions   = (scalar @$positions_ref > 0);
  my $has_markers     = (scalar @$markers_ref > 0);
  my $has_measures    = (scalar @$measures_ref > 0);

#print "has_centromeres: $has_centromeres, ";
#print "draw_label: " . $ini->val('centromere', 'draw_label');
#print ", offset: " . $ini->val('centromere', 'label_offset') , "\n";

  if (($has_centromeres && $ini->val('centromere', 'draw_label') == 1 
        && $ini->val('centromere', 'label_offset') >= 0)
      || ($has_borders && $ini->val('border', 'draw_label') == 1 
        && $ini->val('border', 'label_offset') >= 0)
      || ($has_ranges && $ini->val('range', 'draw_label') == 1 
        && $ini->val('range', 'label_offset') >= 0)
      || ($has_positions && $ini->val('position', 'draw_label') == 1 
        && $ini->val('position', 'label_offset') >= 0)
      || ($has_markers && $ini->val('marker', 'draw_label') == 1 
        && $ini->val('marker', 'label_offset') >= 0)
      || ($has_measures && $ini->val('measure', 'draw_label') == 1 
        && $ini->val('measure', 'label_offset') >= 0)) {
    return 50 ;
  }
  else {
    return 0;
  }
}#labelsRightWidth


################
# print_coords()
# Print out the feature coordinates.

sub print_coords {
   my ($feature_coords_ref, $out_coords_file) = @_;
   my @feature_coords = @$feature_coords_ref;
   open OUT, ">$out_coords_file"
      or die "can't open out $out_coords_file: $!";
   print OUT "#name,chromosome,start,end,x1,y1,x2,y2\n";
print Dumper(@feature_coords);
   foreach my $line (@feature_coords) {
#      print OUT "$key," . $feature_coords{$key} . "\n";
      print OUT "$line\n";
   }
   close OUT;
}#print_coords()


###############
# print_image()
# Print image to file
sub print_image {
  my ($im, $in_path_and_file) = @_;

  open (PNG1, "> $in_path_and_file") 
    or die "can't open out $in_path_and_file: $!";
  binmode (PNG1);
  print PNG1 $im->$image_format;
  close PNG1;
}#print_image


############
# read_gff()
# Read a gff file and put the records into position and range arrays.

sub read_gff {
  my ($filename, $reverse_ruler) = @_;
  
  open GFF, "<$filename" or $error = "Unable to open $filename because: $!";
  if ($error) {
    $dbg->reportError("$error\n");
    $error = "";
  }
  
  else {
    my $marker_count = 0;
    my $line_count   = 0;
    
    while (<GFF>) {
      $line_count++;
      chomp; # get rid of line ending
      
      # The ##FASTA directive indicates the remainder of the file contains
      #   fasta data, per the GFF3 specification
      last if (/^>/ or /##FASTA/); # finished if we've reached fasta data
      
      next if (/^#/);              # skip comment lines 
      next if ((length) == 0);     # skip blank lines
      my $line = $_;

      # NOTE: GFF3 specification does not allow use of spaces to separate 
      #   columns, but CViT does.
      my @record = split /\s+/, $line, 9; # permit more than one space char
      
      # do a spot of error checking and reporting
      if ( (scalar @record) != 9) {
        # make sure this isn't really just a blank record
        $line =~ s/\s//g;
        next if ((length $line) == 0);
        $dbg->reportError("Incorrect number of fields in file $filename, record $line_count [$_]\n    " . scalar @record . " fields found, 9 expected.\n");
        next;
      }
      
      my ($seqname, $source, $type, $start, $end, $score, $strand, $frame, 
          $attributes) = @record;
#print "[$seqname | $source | $type | $start | $end | $score | $strand | $frame | $attributes]\n";
#$dbg->logMessage("$seqname | $source | $type | $start | $end | $score | $strand | $frame | $attributes\n");

      if (lc($type) eq 'chromosome') {        # defines a chromosome
         push @chromosomes, [@record];
      }
      elsif (lc($type) eq 'border') {        # defines a border
         push @borders, [@record];
      }
      elsif (lc($type) eq 'centromere') {     #defines a centromere
         push @centromeres, [@record];
      }
      elsif (lc($type) eq 'marker') {      #defines a marker location
         push @markers, [@record];
      }
      elsif (lc($type) eq 'measure') {     #defines a measure of importance
         push @measures, [@record];
      }
      elsif (in_array("$source:$type", keys %custom_types)) {
         my $section = $custom_types{"$source:$type"};
         my $glyph = $ini->val($section, 'glyph');
         eval "push @" . $glyph . "s, [\@record]";
      }
      elsif ($start == $end) {             #assume a generic position
         push @positions, [@record];
      }
      else {                              #assume a generic range
         push @ranges, [@record];
      }
      
    }#each line

    close(GFF);
  }#GFF file exists
}#read_gff



##################
# reverse_coords()

sub reverse_coords {
  my ($im, $records_ref) = $_[0];
  my @records = @$records_ref;
  my @mod_records;
  foreach my $record (@records) {
    my ($chromosome, $source, $type, $start, $end, $score, $strand, $frame, 
        $attrs) = @$record;
    $start = $im->get_ruler_max() - $start;
    $end = $im->get_ruler_max() - $end;
    my @new_record = ($chromosome, $source, $type, $start, $end, $score, 
                      $strand, $frame, $attrs);
    push @mod_records, [@new_record];
  }#foreach record
  
  return @mod_records;
}#reverse_coords


#########
# _trim()

sub _trim {
	my $str = shift;
	$str =~ s/^\s+//;
	$str =~ s/\s+$//;
	return $str;
}#trim


