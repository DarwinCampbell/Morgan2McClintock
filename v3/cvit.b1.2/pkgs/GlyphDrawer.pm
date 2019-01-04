#!/usr/bin/perl

# File: GlyphDrawer.pm

# Use: Draws glyphs on a CViT image.

# http://search.cpan.org/dist/GD/GD.pm
# http://perldoc.perl.org/List/Util.html

package GlyphDrawer;
use strict;
use warnings;
use GD;
use List::Util qw(max min);

use Data::Dumper;  # for debugging


#######
# new()

sub new {
  my ($self, $cvit_image, $clr_mgr, $font_mgr, $ini, $dbg) = @_;
  
  $self  = {};
  
  # For colors
  $self->{clr_mgr} = $clr_mgr;
  $self->{font_mgr} = $font_mgr;
  $self->{class_color_names} 
      = [split /,\s*/, $ini->val('general', 'class_colors')];
  
  # The ini file
  $self->{ini} = $ini;
  
  # For debugging
  $self->{dbg} = $dbg;
  
  # The image
  $self->{cvit_image} = $cvit_image;
  
  # Custom glyph types
  my %custom_types;
  foreach my $section ($ini->Sections()) {
    if ($ini->val($section, 'feature')) {
      my $feature_name = $ini->val($section, 'feature');
      $custom_types{$feature_name} = $section;
    }
  }#each section
  $self->{custom_types} = \%custom_types;
  
  # For piling up positions and ranges
  $self->{position_bins}       = {};
  $self->{rt_range_pileup_end} = {};
  $self->{lf_range_pileup_end} = {};
  $self->{bumpout}             = 0;

  # For keeping track of pixel locations of features
#  $self->{feature_coords} = {};
  $self->{feature_coords} = [];
  
  bless($self);
  return $self;
}#new


##############
# draw_glyph()
# Draw glyphs for the given set of records and type.

sub draw_glyph {
  my ($self, $records_ref, $glyph) = @_;

  # Dereference arrays and hashes
  my @records = @$records_ref;

  # Make sure there's something to draw
  if (scalar @records == 0) {
    return;
  }
  
  my $ini = $self->{ini};
  my $def_color_name   = $ini->val($glyph,     'color', 'red');
  my $def_width        = int($ini->val($glyph, 'width', 5));
  my $def_fill         = int($ini->val($glyph, 'fill', 0));
  my $def_shape        = $ini->val($glyph,     'shape', 'circle');
  my $def_offset       = int($ini->val($glyph, 'offset', 0));
  my $def_pileup_gap   = int($ini->val($glyph, 'pileup_gap', 0));
  my $def_draw_label   = int($ini->val($glyph, 'draw_label', 1));
  my $def_font         = int($ini->val($glyph, 'font', 1));
  my $def_font_face    = $ini->val($glyph,     'font_face', '');
  my $def_font_size    = int($ini->val($glyph, 'font_size', 0));
  my $def_label_offset = int($ini->val($glyph, 'label_offset', 5));

  # This applies only if glyph is 'measure'
  my ($heat_colors, $num_heat_colors, $heat_color_unit);
  my ($display, $value_type);
  my ($min, $max);
  if ($glyph eq 'measure') {
    $display     = _trim($ini->val('measure', 'display', 'histogram'));
    $heat_colors = _trim($ini->val('measure', 'heat_colors', 'redgreen'));
    $value_type  = _trim($ini->val('measure', 'value_type', 'score_col'));
     
    # calculate overall min/max values
    if ($value_type eq 'score_col') {
      ($min, $max) = $self->_calc_score_min_max(\@records);
    }
    elsif ($value_type eq 'value_attr') {
      ($min, $max) = $self->_calc_value_min_max(\@records);
    }
    else {
      die "Unknown value type: [$value_type]\n";
    }

#TODO: handle this case better
    if (abs($max - $min) == 0) {
      $self->{dbg}->logMessage("No range of data to display");
      #fudge a solution:
      $max++;
      $min--;
    }
  
    if ($display eq 'heat') {
      # We'll need these colors...
      my $im = $self->{cvit_image}->get_image();
      $self->{clr_mgr}->create_heat_colors($heat_colors, $im);
      my $heat_colors_ref = scalar $self->{clr_mgr}->{heat_colors};
      $num_heat_colors = $self->{clr_mgr}->num_heat_colors();
    
      #...and this interval:
      $heat_color_unit = $num_heat_colors / ($max - $min);
    }
  }
  
  my $im = $self->{cvit_image}->get_image();
  
  # each class will have a different color:
  my %class_colors;
  my $class_color_names = $self->{class_color_names};
  my $next_class_color = 0;

print "Draw " . @records . " $glyph" . "s.\n";
  my %unknown_chrs;
  foreach my $record (@records) {
    my ($chromosome, $source, $type, $start, $end, $score, $strand, $frame, 
        $attrs) = @$record;
    
    # Make sure this record references a known chromosome
    if (!$self->{cvit_image}->known_chromosome($chromosome)) {
      $unknown_chrs{$chromosome} = 1;
      next;
    }
    
    my %attributes = $self->_get_attributes($attrs);

    # These can be overriden within a specific .ini file section:
    my ($color_name, $width, $fill, $shape, $offset, $pileup_gap);
    my ($draw_label, $font, $font_face, $font_size, $label_offset);
    
    # Check for custom overrides. NOTE: 'measure' options can't be overridden
    my $section;
    my $custom_types = $self->{custom_types};
    if ($custom_types->{"$source:$type"} && $glyph ne 'measure') {
       $section = $custom_types->{"$source:$type"};

       # check for overrides
       $color_name   = _trim($ini->val($section, 'color', $def_color_name));
       $width        = int($ini->val($section, 'width', $def_width));
       $fill         = int($ini->val($section, 'fill', $def_fill));
       $shape        = _trim($ini->val($section, 'shape', $def_shape));
       $offset       = int($ini->val($section, 'offset', $def_offset));
       $pileup_gap   = int($ini->val($section, 'pileup_gap', $def_pileup_gap));
       $draw_label   = int($ini->val($section, 'draw_label', $def_draw_label));
       $font         = int($ini->val($section, 'font', $def_font));
       $font_face    = _trim($ini->val($section, 'font_face', $def_font_face));
       $font_size    = int($ini->val($section, 'font_size', $def_font_size));
       $label_offset = int($ini->val($section, 'label_offset', $def_label_offset));
    }
    else {
       $color_name   = $def_color_name;
       $width        = $def_width;
       $fill         = $def_fill;
       $shape        = $def_shape;
       $offset       = $def_offset;
       $pileup_gap   = $def_pileup_gap;
       $draw_label   = $def_draw_label;
       $font         = $def_font;
       $font_face    = $def_font_face;
       $font_size    = $def_font_size;
       $label_offset = $def_label_offset;
    }

    # save these drawing attributes in a temp ini section (in memory only)
    $ini->AddSection('PresentGlyph'); # okay if already exists
    $ini->newval('PresentGlyph', 'width', $width);
    $ini->newval('PresentGlyph', 'fill', $fill);
    $ini->newval('PresentGlyph', 'shape', $shape);
    $ini->newval('PresentGlyph', 'offset', $offset);
    $ini->newval('PresentGlyph', 'pileup_gap', $pileup_gap);
    $ini->newval('PresentGlyph', 'draw_label', $draw_label);
    $ini->newval('PresentGlyph', 'font', $font);
    $ini->newval('PresentGlyph', 'font_face', $font_face);
    $ini->newval('PresentGlyph', 'font_size', $font_size);
    $ini->newval('PresentGlyph', 'label_offset', $label_offset);
    if ($glyph eq 'measure') {
      $ini->newval('PresentGlyph', 'display', $display);
      $ini->newval('PresentGlyph', 'value_type', $value_type);
    }  
    
    # use class color? (not applicable to measures)
    if ($attributes{'class'} && $glyph ne 'measure') {
      my $class = $attributes{'class'};
      if (!$class_colors{$class}) { 
        my $new_color 
              = $self->{clr_mgr}->get_color($im, 
                                            $class_color_names->[$next_class_color], 
                                            1);
        $class_colors{$class} = $class_color_names->[$next_class_color];
        $color_name = $class_colors{$class};
        $next_class_color++;
      }
      else {
        $color_name = $class_colors{$class};
      }
    }
    
    # override color? (not applicable for measures)
    if ($attributes{'color'} && $attributes{'color'} ne '' 
          && $glyph ne 'measure') {
      # overrides setting in .ini file and class color
      $color_name = $attributes{'color'};
    }
    
    # if measure, get value
    my $value;
    if ($glyph eq 'measure') {
      if ($value_type eq 'score_col') {
        $value = $self->_convert_score_to_value($score);
        $value = $value - $min;
        # need to flip values around since 0 = best
        $value = ($max - $min) - $value;
      }
      elsif ($value_type eq 'value_attr') {
        $value = $attributes{'value'};
      }
    }
    
    # calculate relative value (starting from lowest value on scale)
    my $rel_start = $start - $self->{cvit_image}->get_ruler_min();
    my $rel_end   = $end - $self->{cvit_image}->get_ruler_min();

    my ($x1, $y1, $x2, $y2, $pileup);
    
    if ($glyph eq 'measure') {
      if ($type eq 'heatmap_legend') {
        ($x1, $y1, $x2, $y2)
            = $self->_calc_heatmap_legend($chromosome, $rel_start, $rel_end, 
                                          $value, $strand, $min, $max);
        # make sure this will fit on the image
        my $im_width = $self->{cvit_image}->get_image_width();
        my $im_height = $self->{cvit_image}->get_image_height();
        next if ($x1 > $im_width || $x2 > $im_width 
                  || $y1 > $im_height || $y2 > $im_height);

         $self->_draw_heatmap_legend($im, $x1, $y1, $x2, $y2, $min, $max, 
                                     $score, $attributes{id});
      }
      elsif ($display eq 'histogram') {
        ($x1, $y1, $x2, $y2) 
            = $self->_calc_histogram_bar($chromosome, $rel_start, $rel_end, 
                                         $value, $strand, $min, $max);
                                         
        # make sure this will fit on the image
        my $im_width = $self->{cvit_image}->get_image_width();
        my $im_height = $self->{cvit_image}->get_image_height();
        next if ($x1 > $im_width || $x2 > $im_width 
                  || $y1 > $im_height || $y2 > $im_height);

        $self->_draw_histogram_bar($im, $x1, $y1, $x2, $y2, $color_name);
      }
      elsif ($display eq 'heat') {
        ($x1, $y1, $x2, $y2) 
            = $self->_calc_heat_bar($chromosome, $rel_start, $rel_end, $value, 
                                    $strand, $width, $offset);
                                    
        # make sure this will fit on the image
        my $im_width = $self->{cvit_image}->get_image_width();
        my $im_height = $self->{cvit_image}->get_image_height();
        next if ($x1 > $im_width || $x2 > $im_width 
                  || $y1 > $im_height || $y2 > $im_height);

        # Calculate heat color
        my $color_index = int ($value * $heat_color_unit);
        if ($color_index >= $num_heat_colors) { 
          $color_index = $num_heat_colors - 1;
        }
        my $heat_colors_ref = $self->{clr_mgr}->{heat_colors};
        my @heat_colors = @$heat_colors_ref;
        my $color = $heat_colors[$color_index];

        $self->_draw_heat_bar($im, $x1, $y1, $x2, $y2, $color);
      }
    }#draw measure
    
    else {
      my $calc_func = '$self->_calc_' . $glyph . '_location(';
      $calc_func .= "'$chromosome', $rel_start, $rel_end, '$strand')";
      ($x1, $y1, $x2, $y2, $pileup) = eval($calc_func);
      
      # make sure this will fit on the image
      my $im_width = $self->{cvit_image}->get_image_width();
      my $im_height = $self->{cvit_image}->get_image_height();
      next if ($x1 > $im_width || $x2 > $im_width 
                || $y1 > $im_height || $y2 > $im_height);
            
      # draw the glyph
      my $draw_func = "\$self->_draw_$glyph(\$im, $x1, $y1, $x2, $y2, ";
      $draw_func .= "'$color_name')";
      eval($draw_func);
    }#draw non-measure glyph
    
    # get feature name
    my $name = $self->_get_name(\%attributes);

    # draw label, if enabled
    if ($draw_label == 1 && $name && $name ne '' && $pileup < 1) {
      # get font information 
      my $use_ttf;
      if ($font_face ne '' && $font_size ne '') {
        $use_ttf = 1;
        $font_face = $self->{font_mgr}->find_font($font_face);
        if ($font_face eq '') {
          # Can't find font face so fall back to default font
          $use_ttf = 0;
        }
      }
    
      # location
      my $label_x = $x2 + $label_offset;
      my $label_y = $y1 + ($y2 - $y1) / 2;

      # color
      my $label_color = $self->{clr_mgr}->get_color($im, 'black');
    
      # Draw label and get coordinates
#print "Draw $glyph label: offset: $label_offset\n";
#print "x2: $x2, xloc: " . $self->{cvit_image}->get_chrxloc()->{$chromosome} . "\n";
      my @feature_box; #x1, y1, x2, y2
      if ($use_ttf) {
        my ($str_width, $str_height) 
            = $self->{font_mgr}->get_text_dimension($font_face, $font_size, 
                                                    $label_color, $name);
        if ($label_offset < 0 
              || $x2 < $self->{cvit_image}->get_chrxloc()->{$chromosome}) {
          # right-justify on the left side of the chromosome
          $label_x = $self->{cvit_image}->get_chrxloc()->{$chromosome}
                     + $label_offset - $str_width - $width;
#print "  right side\n";
        }
        else {
#print "  left side\n";
          $label_x = $x2 + $label_offset;
        }
        $label_y += int($str_height/2);
        my @bounds = $im->stringFT($label_color, $font_face, $font_size,
                                   0, $label_x, $label_y,   # angle, x, y 
                                   $name);
        if ($offset >= 0 && $label_offset >= 0) {
          @feature_box = (int(min $x1, $label_x),
                          int(min $y1, $label_y-$str_height/2),
                          int(max $x2, $bounds[2]), 
                          int(max $y2, $label_y+$str_height/2)
                         );
        }
        else {
          @feature_box = (int(min $x1, $x2, $bounds[0]),
                          int(min $y1, $label_y-$str_height/2),
                          int(max $x1, $x2, $bounds[2]), 
                          int(max $y2, $label_y+$str_height/2)
                         );
        }
      }#true type font
      
      else {
        my $font_obj   = $self->{font_mgr}->get_font($font);
        my $str_height = $self->{font_mgr}->get_font_height($font);
        $label_y -= $str_height/2;
        my $str_width = length($name) 
                      * $self->{font_mgr}->get_font_width($font);
        if ($label_offset < 0 
              || $x1 < $self->{cvit_image}->get_chrxloc()->{$chromosome}) {

          # right-justify on the left side of the chromosome
          $label_x = $self->{cvit_image}->get_chrxloc()->{$chromosome}
                     - abs($label_offset) - $str_width - $width - abs($offset);
        }
        else {
          $label_x = $x2 + $label_offset;
        }
        $im->string($font_obj, 
                    $label_x, 
                    $label_y,
                    $name, 
                    $label_color);
        if (($self->{cvit_image}->{show_strands} == 1 && $strand eq '-')
            || $offset < 0) {
          @feature_box = ($label_x, 
                          int(min($y1, $label_y)), 
                          int(max($x1, $x2, $label_x+$str_width)), 
                          int(max($y2, $label_y+$str_height))
                         );
        }
        else {
          @feature_box = (int($x1 - $width/2), 
                          int(min($y1, $label_y)), 
                          int($label_x + $label_offset + 5*length($name)), 
                          int(max($y2, $label_y+$str_height))
                         );
        }
      }
      
      # record feature coordinates
#      $self->{feature_coords}->{$name} = "$chromosome,$start,$end,";
#      $self->{feature_coords}->{$name} .= join ',', @feature_box;
      my $line = "$name,$chromosome,$start,$end," . join ',', @feature_box;
      push @{$self->{feature_coords}}, $line;
    }#draw label
    
    else {
#      $self->{feature_coords}->{$name} = "$chromosome,$start,$end,$x1,$y1,$x2,$y2";
      my $line = "$name,$chromosome,$start,$end,$x1,$y1,$x2,$y2";
      push @{$self->{feature_coords}}, $line;
    }#no label
  }#each record

  if (scalar (keys %unknown_chrs)) {
    my $msg = "Some features didn't map to known chromosomes. ";
    $self->{dbg}->logMessage($msg . (join ', ', keys %unknown_chrs) . "\n");
  }
  
  return $im;
}#draw_glyph



###############################################################################
#                            INTERNAL FUNCTIONS                               #
###############################################################################


#########################
# _calc_border_location()

sub _calc_border_location {
  my ($self, $chromosome, $start, $end, $strand) = @_;
  
  my $reverse_ruler = $self->{cvit_image}->{reverse_ruler};
  my $chrxloc_ref   = $self->{cvit_image}->get_chrxloc();
  my $chryloc_ref   = $self->{cvit_image}->get_chryloc();
  my $chrymax_ref   = $self->{cvit_image}->get_chrymax();
  my $scale_factor  = $self->{cvit_image}->{scale_factor};
  my $chrom_width   = $self->{cvit_image}->{chrom_width};
  
  my ($x1, $y1, $x2, $y2);

  # feature start is relative to chr start
  my $range_size = $end - $start;
  if ($reverse_ruler == 1) {
    $y1 = int($chrymax_ref->{$chromosome} - $scale_factor*($start + $range_size));
    $y2 = int($y1 + $range_size * $scale_factor);
  }
  else {
    $y1 = int($chryloc_ref->{$chromosome} + $scale_factor * $start);
    $y2 = int($y1 + $range_size * $scale_factor);
  }

  $x1 = $chrxloc_ref->{$chromosome};
  $x2 = $x1 + $chrom_width;
  
  return ($x1, $y1, $x2, $y2, 0);   # borders don't "pileup"
}#_calc_border_location


#############################
# _calc_centromere_location()

sub _calc_centromere_location {
  my ($self, $chromosome, $start, $end, $strand) = @_;

  my $reverse_ruler = $self->{cvit_image}->{reverse_ruler};
  my $chrxloc_ref   = $self->{cvit_image}->get_chrxloc();
  my $chryloc_ref   = $self->{cvit_image}->get_chryloc();
  my $chrymax_ref   = $self->{cvit_image}->get_chrymax();
  my $scale_factor  = $self->{cvit_image}->{scale_factor};
  my $chrom_width   = $self->{cvit_image}->{chrom_width};
  
  my $ini = $self->{ini};
  my $centromere_overhang = int($ini->val('centromere', 'centromere_overhang'));
  
  my ($x1, $y1, $x2, $y2);
  
  $x1 = int($chrxloc_ref->{$chromosome} - $centromere_overhang);
  $x2 = int($x1 + $chrom_width + 2 * $centromere_overhang);
  
  if ($reverse_ruler == 1) {
    $y1 = int($chrymax_ref->{$chromosome} - $scale_factor * $end);
    $y2 = int($chrymax_ref->{$chromosome} - $scale_factor * $start);
  }
  else {
    $y1 = int($chryloc_ref->{$chromosome} + $scale_factor * $start);
    $y2 = int($chryloc_ref->{$chromosome} + $scale_factor * $end);
  }

  return ($x1, $y1, $x2, $y2, 0);  # centromeres don't "pileup"
}#_calc_centromere_location


##################
# _calc_heat_bar()

# NOTE: only displays on right side of chrom

sub _calc_heat_bar {
  my ($self, $chromosome, $start, $end, $value, $strand, $width, 
      $offset) = @_;

  my $reverse_ruler = $self->{cvit_image}->{reverse_ruler};
  my $chrxloc_ref   = $self->{cvit_image}->get_chrxloc();
  my $chryloc_ref   = $self->{cvit_image}->get_chryloc();
  my $chrymax_ref   = $self->{cvit_image}->get_chrymax();
  my $chrom_width   = $self->{cvit_image}->{chrom_width};
  my $scale_factor  = $self->{cvit_image}->{scale_factor};

  my ($x1, $y1, $x2, $y2);
  
  $x1 = $chrxloc_ref->{$chromosome} + $chrom_width + $offset;
  $x2 = $x1 + $width;
  
  if ($reverse_ruler == 1) {
    $y1 = $chrymax_ref->{$chromosome} - $scale_factor * $end;
    $y2 = $chrymax_ref->{$chromosome} - $scale_factor * $start;
  }
  else {
    $y1 = $chryloc_ref->{$chromosome} + $scale_factor * $start;
    $y2 = $chryloc_ref->{$chromosome} + $scale_factor * $end;
  }
  
  # make sure range is at least 1 pixel:
  if ( int ($y2 - $y1) < 1 ) { $y2 = $y1+1; }

  return ($x1, $y1, $x2, $y2);
}#_calc_heat_bar


sub _calc_heatmap_legend {
  my ($self, $chromosome, $start, $end, $min_label, $max_label, $label) = @_;

  my $cvit_image   = $self->{cvit_image};
  my $chrxloc_ref  = $cvit_image->get_chrxloc();
  my $chryloc_ref  = $cvit_image->get_chryloc();
  my $chrom_width  = $cvit_image->{chrom_width};
  my $scale_factor = $cvit_image->{scale_factor}; 
  
  my $inc   = 10;
  my $width = int(($end - $start)*$scale_factor / $inc);

  # calculate starting location:
  my $y1 = int($chryloc_ref->{$chromosome} + $scale_factor * $start);
  my $y2 = $y1+$width;
  my $x1 = int($chrxloc_ref->{$chromosome} + $chrom_width);
  my $x2 = $x1 + $inc*$width;

  return ($x1, $x2, $y1, $y2);
}#_calc_heatmap_legend


#######################
# _calc_histogram_bar()

# NOTE: only displays on right side of chrom

sub _calc_histogram_bar {
  my ($self, $chromosome, $start, $end, $value, $strand, $min, $max) = @_;

  my $reverse_ruler = $self->{cvit_image}->{reverse_ruler};
  my $chrxloc_ref   = $self->{cvit_image}->get_chrxloc();
  my $chryloc_ref   = $self->{cvit_image}->get_chryloc();
  my $chrymax_ref   = $self->{cvit_image}->get_chrymax();
  my $chrom_width   = $self->{cvit_image}->{chrom_width};
  my $chrom_spacing = $self->{cvit_image}->{chrom_spacing};
  my $scale_factor  = $self->{cvit_image}->{scale_factor};
  
  # Note that histograms assume the min is 0, so adjust the values accordingly
  $value = $value - $min;
  my $max_histogram = $chrom_spacing - 2 * $chrom_width;
  # .45 : don't fill entire space between chromosomes
  my $histogram_unit = .45 * ($max_histogram / ($max - $min)); 

  my ($x1, $y1, $x2, $y2);

  $x1 = int($chrxloc_ref->{$chromosome} + $chrom_width + 1);
  $x2 = int($x1 + $value * $histogram_unit);
  
  if ($reverse_ruler == 1) {
    $y1 = int($chrymax_ref->{$chromosome} - $scale_factor * $end);
    $y2 = int($chrymax_ref->{$chromosome} - $scale_factor * $start);
  }
  else {
    $y1 = int($chryloc_ref->{$chromosome} + $scale_factor * $start);
    $y2 = int($chryloc_ref->{$chromosome} + $scale_factor * $end);
  }
  
  # make sure histogram bar is at least 1 pixel high:
  if (int($y2 - $y1) < 1) { $y2 = $y1+1; }
  
  return ($x1, $y1, $x2, $y2);
}#_calc_histogram_bar


#########################
# _calc_marker_location()

sub _calc_marker_location {
  my ($self, $chromosome, $start, $end, $strand) = @_;
  
  my $reverse_ruler = $self->{cvit_image}->{reverse_ruler};
  my $chrxloc_ref  = $self->{cvit_image}->get_chrxloc();
  my $chryloc_ref  = $self->{cvit_image}->get_chryloc();
  my $chrymax_ref   = $self->{cvit_image}->get_chrymax();
  my $chrom_width  = $self->{cvit_image}->{chrom_width};
  my $scale_factor = $self->{cvit_image}->{scale_factor};
  
  my $ini = $self->{ini};
  my $width  = int($ini->val('PresentGlyph', 'width', 5));
  my $offset = int($ini->val('PresentGlyph', 'offset', 0));
  
  my ($x1, $y1, $x2, $y2);
  
  # calculate y location on image for marker
  if ($reverse_ruler == 1) {
    $y1 = int($chrymax_ref->{$chromosome} - $scale_factor * $start);
    $y2 = $y1;
  }
  else {
    $y1 = int($chryloc_ref->{$chromosome} + $scale_factor * $start);
    $y2 = $y1;
  }

  # calculate x locations on image for marker
  if ($self->{cvit_image}->{show_strands} == 1) {
    if ($strand eq '-') {
      # left side
      $x1 = $chrxloc_ref->{$chromosome} - $width - $offset;
      $x2 = $x1 + $width;
    }
    elsif ($strand eq '+') {
      # right side
      $x1 = $chrxloc_ref->{$chromosome} + $chrom_width + $offset;
      $x2 = $x1 + $width;
    }
    else {
      # inside chrom
      $x1 = $chrxloc_ref->{$chromosome};
      $x2 = $x1 + $chrom_width;
    }
  }
  else {
    # right side
    $x1 = $chrxloc_ref->{$chromosome} + $chrom_width + $offset;
    $x2 = $x1 + $width;
  }
  
  return ($x1, $y1, $x2, $y2, 0);  # markers don't "pileup"
}#_calc_marker_location


###########################
# _calc_position_location()

sub _calc_position_location {
  my ($self, $chromosome, $start, $end, $strand) = @_;
  
  my $reverse_ruler = $self->{cvit_image}->{reverse_ruler};
  my $chrxloc_ref   = $self->{cvit_image}->get_chrxloc();
  my $chryloc_ref   = $self->{cvit_image}->get_chryloc();
  my $chrymax_ref   = $self->{cvit_image}->get_chrymax();
  my $chrom_width   = $self->{cvit_image}->{chrom_width};
  my $scale_factor  = $self->{cvit_image}->{scale_factor};


  my $ini = $self->{ini};
  my $width  = int($ini->val('PresentGlyph', 'width', 5));
  my $offset = int($ini->val('PresentGlyph', 'offset', 5));
  
  my $pileup_width = $width + int($ini->val('PresentGlyph', 'pileup_gap', 0));
  
  # calculate y location:
  my $y;
  if ($reverse_ruler == 1) {
    $y = int($chrymax_ref->{$chromosome} - $scale_factor * $start);
  }
  else {
    $y = int($chryloc_ref->{$chromosome} + $scale_factor * $start);
  }

  # calculate x position (pile up close postions)
  my ($x, $pileup_count);
  my $position_bins = $self->{position_bins};
  my $bin = $y / $width;
  if ($offset < 0 
        || ($self->{cvit_image}->{show_strands} == 1 && $strand eq '-')) {
    # draw on left side of chrom
    $pileup_count = $position_bins->{$chromosome}{'minus'}[$bin]++;
    $x = int($chrxloc_ref->{$chromosome} - $offset - $width/2
               - $pileup_count * $pileup_width);
  }
  else {
    # draw on right side of chrom
    $pileup_count = $position_bins->{$chromosome}{'plus'}[$bin]++;
    $x = int($chrxloc_ref->{$chromosome} + $chrom_width + $offset + $width/2
               + $pileup_count * $pileup_width + 1);
  }

  return ($x, $y, $x, $y, $pileup_count);
}#_calc_position_location


########################
# _calc_range_location()

sub _calc_range_location {
  my ($self, $chromosome, $start, $end, $strand) = @_;

  my $reverse_ruler = $self->{cvit_image}->{reverse_ruler};
  my $chrxloc_ref  = $self->{cvit_image}->get_chrxloc();
  my $chryloc_ref  = $self->{cvit_image}->get_chryloc();
  my $chrymax_ref   = $self->{cvit_image}->get_chrymax();
  my $scale_factor = $self->{cvit_image}->{scale_factor};
  my $chrom_width  = $self->{cvit_image}->{chrom_width};

  my $ini = $self->{ini};
  my $width         = $ini->val('PresentGlyph', 'width');
  my $offset        = $ini->val('PresentGlyph', 'offset');
  my $pileup_gap    = $ini->val('PresentGlyph', 'pileup_gap');

  my ($x1, $x2, $y1, $y2);
  
  # feature start is relative to chr start
  my $range_size = $end - $start;
  if ($reverse_ruler == 1) {
    $y1 = int($chrymax_ref->{$chromosome} - $scale_factor*($start+$range_size));
    $y2 = int($y1 + $range_size * $scale_factor);
  }
  else {
    $y1 = int($chryloc_ref->{$chromosome} + $scale_factor * $start);
    $y2 = int($y1 + $range_size * $scale_factor);
  }
  
  # check to see if this range needs to be bumped out
  my $rt_range_pileup_end_ref = $self->{rt_range_pileup_end};
  my %rt_range_pileup_end     = %$rt_range_pileup_end_ref;
  my $lf_range_pileup_end_ref = $self->{lf_range_pileup_end};
  my %lf_range_pileup_end     = %$lf_range_pileup_end_ref;
  
  my $bumpout = $self->{bumpout};
  my $pileup = 1;
  
  if ($self->{cvit_image}->{show_strands} == 1 && $strand eq '+') {
    if (!$rt_range_pileup_end{$chromosome} 
          || $end*$scale_factor < $rt_range_pileup_end{$chromosome}) {
       # starting a new chromosome; reset pileup_end
       $rt_range_pileup_end{$chromosome} = int($end * $scale_factor);
       $bumpout = 0;
    }
    elsif (int($start*$scale_factor) <= $rt_range_pileup_end{$chromosome}) {
       # bump out the range bar
       $pileup = 2; # just indicates that ranges are piled up, not actual count
       $bumpout += $width + $pileup_gap;
    }
    else {
       # start a new pileup
       $rt_range_pileup_end{$chromosome} = int($end * $scale_factor);
       $bumpout = 0;
    }
  }#range on right side of chromosome
  
  else {
    if (!$lf_range_pileup_end{$chromosome} 
          || $end*$scale_factor < $lf_range_pileup_end{$chromosome}) {
       # starting a new chromosome; reset pileup_end
       $lf_range_pileup_end{$chromosome} = int($end * $scale_factor);
       $bumpout = 0;
    }
    elsif (int($start*$scale_factor) <= $lf_range_pileup_end{$chromosome}) {
       # bump out the range bar
       $pileup = 2; # just indicates that ranges are piled up, not actual count
       $bumpout += $width + $pileup_gap;
    }
    else {
       # start a new pileup
       $lf_range_pileup_end{$chromosome} = int($end * $scale_factor);
       $bumpout = 0;
    }
  }#range on left side of chromosome

  $self->{rt_range_pileup_end} = \%rt_range_pileup_end;
  $self->{lf_range_pileup_end} = \%lf_range_pileup_end;
  $self->{bumpout}             = $bumpout;

  if (($self->{cvit_image}->{show_strands} == 1 && $strand eq '-')
            || $offset < 0) {
    # draw to the left of the chromosome
    $x1 = $chrxloc_ref->{$chromosome} - $offset - $bumpout - $width;
    $x2 = $x1 + $width;
  }
  elsif ($self->{cvit_image}->{show_strands} == 1 
            && $strand ne '+' && $strand ne '-') {
    # draw on top of the two strands (ignore bumpout)
    $x1 = $chrxloc_ref->{$chromosome} + 2;
    $x2 = $x1 + $chrom_width - 4;
  }#show chromosome strands
  else {
    # draw right of chromosome according to offset
    $x1 = $chrxloc_ref->{$chromosome}
          + $chrom_width + $offset + $bumpout;
    $x2 = $x1 + $width;
  }

  return ($x1, $y1, $x2, $y2, $pileup);
}#_calc_range_location


#######################
# _calc_score_min_max()

sub _calc_score_min_max {
  my ($self, $records_ref) = @_;
  
  my @records = @$records_ref;
  my ($min, $max);
  
  # get min and max 'score' column (assumed to be an e-value)
  foreach my $record (@records) {
    my ($d1, $d2, $d3, $d4, $d5, $score, $d6, $d7, $d8) = @$record;
    my $value = $self->_convert_score_to_value($score);
    if (!$min || $value < $min) { $min = $value; }
    if (!$max || $value > $max) { $max = $value; }
  }#each record

  return ($min, $max);
}#calc_value_min_max


#######################
# _calc_value_min_max()

sub _calc_value_min_max {
  my ($self, $records_ref) = @_;
  
  my @records = @$records_ref;
  my ($min, $max);
  
  my $record_count = 0;
  foreach my $record (@records) {
    $record_count++;
    
    my ($d1, $d2, $d3, $d4, $d5, $d6, $d7, $d8, $attributes) = @$record;
    my %attributes = $self->_get_attributes($attributes);
    
    if (!$attributes{'value'}) {
       $self->{dbg}->reportError("No value in record $record_count");
    }
    my $value = int($attributes{'value'});
    if (!$min || $min > $value) { $min = $value; }
    if (!$max || $max < $value) { $max = $value; }
  }#each record

  return ($min, $max);
}#calc_value_min_max


###########################
# _convert_score_to_value()

sub _convert_score_to_value {
  my ($self, $score) = @_;
  
  # nothing can score better than this (flattens the steep end of the curve): 
  my $best = 1e-70;
  my $a = log($best)/log(10);
  my $value = ($score < $best) ? $best : $score;
  return (($a - log($value)) / $a);
}#_convert_score_to_value


###############
# _draw_border

sub _draw_border {
  my ($self, $im, $x1, $y1, $x2, $y2, $color_name) = @_;
  
  my $fill = $self->{ini}->val('PresentGlyph', 'fill');
  
  if ($fill == 1) {
    $im->filledRectangle($x1, $y1, $x2, $y2, 
                         $self->{clr_mgr}->get_color($im, $color_name, 1));
    $im->line($x1, $y1, $x2, $y1, $self->{clr_mgr}->get_color($im, 'black'));
    $im->line($x1, $y2, $x2, $y2, $self->{clr_mgr}->get_color($im, 'black'));
  }
  else {
    # indicate just top and bottom border of range with horizontal lines
    $im->line($x1, $y1, $x2, $y1, $self->{clr_mgr}->get_color($im, $color_name));
    $im->line($x1, $y2, $x2, $y2, $self->{clr_mgr}->get_color($im, $color_name));
  }
}#_draw_border


####################
# _draw_centromere()

sub _draw_centromere {
  my ($self, $im, $x1, $y1, $x2, $y2, $color_name) = @_;
  $im->filledRectangle($x1, $y1, $x2, $y2, 
                       $self->{clr_mgr}->get_color($im, $color_name));
}#_draw_centromere


##################
# _draw_heat_bar()

sub _draw_heat_bar {
  my ($self, $im, $x1, $y1, $x2, $y2, $color) = @_;
  $im->filledRectangle($x1, $y1, $x2, $y2, $color);
}#_draw_heat_bar


########################
# _draw_heatmap_legend()
# Draw a legend image showing the range of heat colors

sub _draw_heatmap_legend {
  my ($self, $im, $init_x1, $init_x2, $init_y1, $init_y2, $min, $max, $score, $label) = @_;

  my $ini          = $self->{ini};
  my $scale_factor = $self->{cvit_image}->{scale_factor}; 
  
  my $heat_colors = $self->{ini}->val('measure', 'heat_colors', 'redgreen');
  
  # Create heat colors and get a handy pointer to the array
  $self->{clr_mgr}->create_heat_colors($heat_colors, $im);
  my $heat_colors_ref = scalar $self->{clr_mgr}->{heat_colors};

  my $inc = 10;
  my $color_inc = $self->{clr_mgr}->num_heat_colors() / $inc;
  my $width = ($init_x2 - $init_x1) / $inc;
  my $font;

  # calculate starting location:
  my $y1 = $init_y1;
  my $y2 = $y1+$width;
  my $x1 = $init_x1;
  my $x2 = $x1+$width;

  # show the range of colors
  for (my $i=0; $i<$inc; $i++) {
    my $color = $heat_colors_ref->[$color_inc * $i];
    $im->filledRectangle($x1, $y1, $x2, $y2, $color);
    $y1 = $y2;
    $y2 += $width;
  }
  
  # label range
  $x2 = $x1 + 2*$width; 
  $y1 = $init_y1;

  my $value_type = _trim($ini->val('measure', 'value_type'));
  my ($min_label, $max_label);
  if ($value_type eq 'score_col') {
    #assumed to be an e-value
    $value_type = 'e-value';
    $min_label = '0';
    $max_label = $score;
  }
  elsif ($value_type eq 'value_attr') {
    $value_type = 'value';
    $min_label = sprintf("%.2d", $min);
    $max_label = sprintf("%.2d", $max);
  }

  # if possible, use tiny font
  my $tiny_font_face 
        = $self->{font_mgr}->find_font(
            $self->{ini}->val('general', 'tiny_font_face', ''));
  if ($tiny_font_face ne '') {
    #TODO: use font manager to find font
    my $font_size = 6;
    $im->stringFT($self->{clr_mgr}->get_color('black'),
                  $tiny_font_face, $font_size, 
                  0, $x2, $y1, 
                  $min_label);
    $im->stringFT($self->{clr_mgr}->get_color('black'),
                  $tiny_font_face, $font_size, 
                  0, $x2, $y2, 
                  $max_label);
  }#use tiny font
  else {
    # fall back to generic font
    $font = $self->{font_mgr}->get_font(3);
  
    $im->string($font, $x2, $y1-6, $min_label, 
                $self->{clr_mgr}->get_color($im, 'black')); 
    $im->string($font, $x2, $y2-6, $max_label, 
                $self->{clr_mgr}->get_color($im, 'black')); 
  }#use generic font

  my ($str_width, $str_height);
  if ($ini->val('measure', 'font_face', '') ne ''
        && $ini->val('measure', 'font_size', 0) != 0) {
    my $font_face  = $self->{font_mgr}->find_font($ini->val('measure', 'font_face'));
    my $font_size  = $ini->val('measure', 'font_size');
    my $font_color = $self->{clr_mgr}->get_color($im, 'black');
#print "draw heatmap legend\n";
    ($str_width, $str_height) 
          = $self->{font_mgr}->get_text_dimension(
              $font_face, $font_size, $font_color, ' ');
    $im->stringFT($font_color, $font_face, $font_size, 
                  0, 
                  $x2 + 2*$width + 2, 
                  $y1 + ($y2 - $y1) / 2 + $str_height/2, 
                  "$label $value_type");
  }
  else {
    $font = $ini->val('measure', 'font', 2);
    my $font_name = $self->{font_mgr}->get_font($font);
    $str_height = $self->{font_mgr}->get_font_height($font);
    $im->string($font_name, 
                $x2 + 2*$width + 2, 
                $y1 + ($y2 - $y1) / 2 - 3*$str_height/4,
                "$label $value_type", 
                $self->{clr_mgr}->get_color($im, 'black'));
  }
}#_draw_heatmap_legend


#######################
# _draw_histogram_bar()

sub _draw_histogram_bar {
  my ($self, $im, $x1, $y1, $x2, $y2, $color_name) = @_;
  $im->filledRectangle($x1, $y1, $x2, $y2, 
                       $self->{clr_mgr}->get_color($im, $color_name));
}#_draw_histogram_bar


################
# _draw_marker()

sub _draw_marker {
  my ($self, $im, $x1, $y1, $x2, $y2, $color_name) = @_;
  my $color = $self->{clr_mgr}->get_color($im, $color_name);
  $im->line($x1, $y1, $x2, $y1, $color);
}#_draw_marker


##################
# _draw_position()

sub _draw_position {
  my ($self, $im, $x1, $y1, $x2, $y2, $color_name) = @_;

  my $ini = $self->{ini};
  my $shape = $ini->val('PresentGlyph', 'shape');
  my $width = $ini->val('PresentGlyph', 'width');

  my $color = $self->{clr_mgr}->get_color($im, $color_name);

  if ($shape =~ /^circle/) { # circle
    # centers the circle on the x, y position
    $im->arc($x1, 
             $y1,, 
             $width, 
             $width, 
             0, 360, $color);
    $im->fill($x1, $y1, $color);
  }
  
  elsif ($shape =~ /^rect/) { # rectangle
    # center the rectangle the way circles are centered above
    if ($width < 3) { # min rect height seems to be 3 pixels so draw a line
      $im->line($x1-$width/2, $y1, $x1+$width/2, $y1, $color);
    }
    else {
      $im->filledRectangle($x1 - $width/2, $y1 - $width/2, $x1 + $width/2, 
                           $y1 + $width/2, $color);
    }
  }
  
  elsif ($shape =~ /^doublecircle/) {
    $im->arc($x1-$width/2, 
             $y1 + $width/2, 
             $width, 
             $width, 
             0, 360, $color);
    $im->fill($x1-$width/2, $y1 + $width/2, $color);
    
    $im->arc($x1+$width/2, 
             $y1 + $width/2, 
             $width, 
             $width, 
             0, 360, $color);
    $im->fill($x1+$width/2, $y1 + $width/2, $color);
  }
  
  else { die " unknown dot shape [$shape] (should be circle, doublecircle or rect)\n" }
}#_draw_position


###############
# _draw_range()

sub _draw_range {
  my ($self, $im, $x1, $y1, $x2, $y2, $color_name) = @_;

  $im->filledRectangle($x1, $y1, $x2, $y2, 
                       $self->{clr_mgr}->get_color($im, $color_name, 1));
}#_draw_range


###################
# _get_attributes()

sub _get_attributes {
   my ($self, $attrs) = @_;
   my @attribute_list = split /;/, $attrs;
   return map { lc($self->_attr_key($_)) => $self->_attr_val($_) } @attribute_list;
}#_get_attributes

sub _attr_key {
  my ($self, $keystr) = @_;
  my @parts = split(/=/, $keystr);
  return $parts[0];
}
sub _attr_val {
  my ($self, $valstr) = @_;
  my @parts = split(/=/, $valstr);
  return $parts[1];
}


#############
# _get_name()

sub _get_name {
   my ($self, $attributes) = @_;
   if ($attributes->{'name'}) {
      return $attributes->{'name'};
   }
   elsif ($attributes->{'id'}) {
      return $attributes->{'id'};
   }
   elsif ($attributes->{'clone'}) {
      return $attributes->{'clone'};
   }
   else {
      return '';
   }
}#_get_name


########
# _trim

sub _trim {
	my $str = shift;
	$str =~ s/^\s+//;
	$str =~ s/\s+$//;
	return $str;
}




1;  # so that the require or use succeeds