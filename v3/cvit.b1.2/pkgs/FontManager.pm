#!/usr/bin/perl

# File: FontManager.pm

# Use: Manage fonts for CViT.

package FontManager;
use strict;
use warnings;
use GD;

use Data::Dumper;


#######
# new()

sub new {
  my $self = $_[0];
  
  $self = {};
  
  # create fonts
  my $gdLargeFont      = GD::gdLargeFont;
  my $gdMediumBoldFont = GD::gdMediumBoldFont;
  my $gdSmallFont      = GD::gdSmallFont;
  my $gdTinyFont       = GD::gdTinyFont;
  my @fonts = ($gdLargeFont, $gdMediumBoldFont, $gdSmallFont, $gdTinyFont);
  $self->{fonts} = [@fonts];

  bless($self);
  return $self;
}#new


#############
# find_font()

sub find_font {
  my ($self, $font_face) = @_;
  if (-e 'fonts/'.$font_face) {
    return 'fonts/'.$font_face;
  }
  
  elsif (-e $font_face) {
    return $font_face;
  }
  
  else {
    if (opendir(DIR, "fonts")) {
      my @dirs = readdir(DIR);
      foreach my $dir (@dirs) {
        if (-d "fonts/$dir") {
          opendir(SUBDIR, "fonts/$dir");
          my @files = grep { /$font_face/ } readdir(SUBDIR);
          if (scalar @files > 0) {
            return "fonts/$dir/$font_face";
          }
          closedir(SUBDIR);
        }
      }
      closedir(DIR);
    }
  }
  
  # If we get here we failed
  print "WARNING: Unable to find font file $font_face\n";
  return '';
}#find_font


############
# get_font()

sub get_font {
  my ($self, $font_num) = @_;
  my $fonts_ref = $self->{fonts};
  if ($font_num < scalar @$fonts_ref) {
    return $fonts_ref->[$font_num];
  }
  else {
    return $fonts_ref->[0];
  }
}#get_font


sub get_font_height {
  my ($self, $font_num) = @_;
  if ($font_num == 0) {
    return 16;
  }
  elsif ($font_num == 1) {
    return 14;
  }
  elsif ($font_num == 2) {
    return 13;
  }
  elsif ($font_num == 3) {
    return 8;
  }
}#get_font_height


sub get_font_width {
  my ($self, $font_num) = @_;
  if ($font_num == 0) {
    return 8;
  }
  elsif ($font_num == 1) {
    return 7;
  }
  elsif ($font_num == 2) {
    return 6;
  }
  elsif ($font_num == 3) {
    return 5;
  }
}#get_font_width


######################
# get_text_dimension()

sub get_text_dimension {
  my ($self, $font_face, $font_size, $font_color, $string) = @_;

  # bounds: x1, y2, x2, y2, x2, y1, x1, y1
  my @bounds = GD::Image->stringFT($font_color, 
                                   $font_face, 
                                   $font_size, 
                                   0, 0, 0, # angle,x,y
                                   $string);
  my $str_width = $bounds[2] - $bounds[0];
  my $str_height = $bounds[1] - $bounds[5];
  
  return ($str_width, $str_height);
}# get_text_dimension

1;  # so that the require or use succeeds