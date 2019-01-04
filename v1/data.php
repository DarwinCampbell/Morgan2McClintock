<?php
  function extract_um_value2($locus_name,$modified_value,$cmrn_cmck_value,$cmrn_um_value,$short_arm)
  {
    $prev_cm_value = array_shift($cmrn_cmck_value);
    $curr_cm_value = array_shift($cmrn_cmck_value);
    $next_cm_value = array_shift($cmrn_cmck_value);
    $prev_um_value = array_shift($cmrn_um_value);
    $curr_um_value = array_shift($cmrn_um_value);
    $coord = $modified_value;
    $return_value = 0.0;
    $cent_passed = false;
    while(strlen($curr_cm_value) > 0)
    {
      if(($short_arm) && (!($cent_passed)) && (($coord == $curr_cm_value) || (($coord < $prev_cm_value) && ($coord > $curr_cm_value))))
        $return_value = $curr_um_value;
      else if((!($short_arm)) && ($cent_passed) && (($coord == $curr_cm_value) || (($coord > $prev_cm_value) && ($coord < $curr_cm_value))))
        $return_value = $curr_um_value;
      else if(($coord == 0) && ($curr_cm_value == 0))
        $return_value = $curr_um_value;
      $prev_cm_value = $curr_cm_value;
      $curr_cm_value = $next_cm_value;
      $next_cm_value = array_shift($cmrn_cmck_value);
      $prev_um_value = $curr_um_value;
      $curr_um_value = array_shift($cmrn_um_value);
      if($curr_cm_value == 0.00)
        $cent_passed = true;
    }
    return $return_value;
  }

  function extract_cm_value($locus_name,$modified_value,$cmrn_cm_value,$cmrn_cmck_value,$short_arm)
  {
    $prev_cm_value = array_shift($cmrn_cm_value);
    $curr_cm_value = array_shift($cmrn_cm_value);
    $next_cm_value = array_shift($cmrn_cm_value);
    $prev_cmc_value = array_shift($cmrn_cmck_value);
    $curr_cmc_value = array_shift($cmrn_cmck_value);
    $return_value = $prev_cm_value;
    $cent_passed = false;
    $coord = $modified_value;
    while(strlen($curr_cm_value) > 0)
    {
      if(($short_arm) && (!($cent_passed)) && (($coord == $curr_cmc_value) || (($coord < $prev_cmc_value) && ($coord > $curr_cmc_value))))
        $return_value = $curr_cm_value;
      else if((!($short_arm)) && ($cent_passed) && (($coord == $curr_cmc_value) || (($coord > $prev_cmc_value) && ($coord < $curr_cmc_value))))
        $return_value = $curr_cm_value;
      else if(($coord == 0) && ($curr_cmc_value == 0))
        $return_value = $curr_cm_value;
      $prev_cm_value = $curr_cm_value;
      $curr_cm_value = $next_cm_value;
      $next_cm_value = array_shift($cmrn_cm_value);
      $prev_cmc_value = $curr_cmc_value;
      $curr_cmc_value = array_shift($cmrn_cmck_value);
      if($curr_cmc_value == 0.00)
        $cent_passed = true;
    }
    return $return_value;
  }

  function extract_cmc_value($name,$coord,$cmrn_cm_value,$cmrn_cmc_value)
  {
    $prev_cm_value = array_shift($cmrn_cm_value);
    $curr_cm_value = array_shift($cmrn_cm_value);
    $next_cm_value = array_shift($cmrn_cm_value);
    $prev_cmc_value = array_shift($cmrn_cmc_value);
    $curr_cmc_value = array_shift($cmrn_cmc_value);
    $return_value = 1.00;

    while(strlen($curr_cm_value) > 0)
    {
      $min_cm_value = $curr_cm_value - ($curr_cm_value - $prev_cm_value) / 2;
      $max_cm_value = $curr_cm_value + ($next_cm_value - $curr_cm_value) / 2;
      if(($coord <= $curr_cm_value) && ($coord > $prev_cm_value))
        $return_value = $curr_cmc_value;
      $prev_cm_value = $curr_cm_value;
      $curr_cm_value = $next_cm_value;
      $next_cm_value = array_shift($cmrn_cm_value);
      $curr_cmc_value = array_shift($cmrn_cmc_value);
    }

    if(substr(strtolower($name),0,4) == "cent")
      return 0.00;
    else
      return $return_value;
  }

  function extract_um_value($name,$coord,$cmrn_cm_value,$cmrn_um_value)
  {
    $prev_cm_value = array_shift($cmrn_cm_value);
    $curr_cm_value = array_shift($cmrn_cm_value);
    $next_cm_value = array_shift($cmrn_cm_value);
    $prev_um_value = array_shift($cmrn_um_value);
    $curr_um_value = array_shift($cmrn_um_value);
    $return_value = 0.0;

    while(strlen($curr_cm_value) > 0)
    {
      $min_cm_value = $curr_cm_value - ($curr_cm_value - $prev_cm_value) / 2;
      $max_cm_value = $curr_cm_value + ($next_cm_value - $curr_cm_value) / 2;
      if(($coord <= $curr_cm_value) && ($coord > $prev_cm_value))
        $return_value = $curr_um_value;
      $prev_cm_value = $curr_cm_value;
      $curr_cm_value = $next_cm_value;
      $next_cm_value = array_shift($cmrn_cm_value);
      $prev_um_value = $curr_um_value;
      $curr_um_value = array_shift($cmrn_um_value);
    }

    if(($coord > 50) && ($return_value < 1))
      return $prev_um_value;
    else
      return $return_value;
  }


  function get_cmrn_map_name($chrom)
  {

  return '../data/cmrn/cmrn' . $chrom;

  /*
    if($chrom == 1) return "cmrn1";
    else if($chrom == 2) return "cmrn2";
    else if($chrom == 3) return "cmrn3";
    else if($chrom == 4) return "cmrn4";
    else if($chrom == 5) return "cmrn5";
    else if($chrom == 6) return "cmrn6";
    else if($chrom == 7) return "cmrn7";
    else if($chrom == 8) return "cmrn8";
    else if($chrom == 9) return "cmrn9";
    else if($chrom == 10) return "cmrn10";
    */

  }

  function get_genetic_map_name($chrom,$map)
  {

    if ($map == 1) {
        $prefix = "../data/umc/";
    } else if ($map == 2) {
        $prefix = "../data/gen/";
    }

    if(($chrom == 1) && ($map == 1)) $file = "umc981";
    else if(($chrom == 2) && ($map == 1)) $file = "umc982";
    else if(($chrom == 3) && ($map == 1)) $file = "umc983";
    else if(($chrom == 4) && ($map == 1)) $file = "umc984";
    else if(($chrom == 5) && ($map == 1)) $file = "umc985";
    else if(($chrom == 6) && ($map == 1)) $file = "umc986";
    else if(($chrom == 7) && ($map == 1)) $file = "umc987";
    else if(($chrom == 8) && ($map == 1)) $file = "umc988";
    else if(($chrom == 9) && ($map == 1)) $file = "umc989";
    else if(($chrom == 10) && ($map == 1)) $file = "umc9810";
    else if(($chrom == 1) && ($map == 2)) $file = "gen1";
    else if(($chrom == 2) && ($map == 2)) $file = "gen2";
    else if(($chrom == 3) && ($map == 2)) $file = "gen3";
    else if(($chrom == 4) && ($map == 2)) $file = "gen4";
    else if(($chrom == 5) && ($map == 2)) $file = "gen5";
    else if(($chrom == 6) && ($map == 2)) $file = "gen6";
    else if(($chrom == 7) && ($map == 2)) $file = "gen7";
    else if(($chrom == 8) && ($map == 2)) $file = "gen8";
    else if(($chrom == 9) && ($map == 2)) $file = "gen9";
    else if(($chrom == 10) && ($map == 2)) $file = "gen10";

    return $prefix . $file;

  }

  $chrom = $_POST["chrom"];
  $map = $_POST["map"];
  $coords = $_POST["coords"];

  $legit_data = true;

  $cmrn_map_name = get_cmrn_map_name($chrom);

  if(strlen($cmrn_map_name) == 0)
  {
    $legit_data = false;
    $data_error_code = 1;
  }

  $locus_names = array();
  $locus_values = array();
  $temp_use = array();
  $temp_use2 = array();
  $temp_use3 = array();

  $min_coord = 999;
  $max_coord = -999;
  $cent_coord = -999;

  $cmrn_file = fopen($cmrn_map_name,"r");

  if(($map == 0) && (strlen($coords) == 0))
  {
    $legit_data = false;
    $data_error_code = 2;
  }
  else if(strlen($coords) > 0)
  {
    $value = trim(strtok($coords,"\n"));
    while(strlen($value) > 0)
    {
      array_push($temp_use,$value);
      $value = strtok("\n");
    }
    $temp_use3 = $temp_use;
    $value = array_pop($temp_use);
    while(strlen($value) > 0)
    {
      $value1 = strtok($value,"	");
      $value2 = strtok("	");
      if(strlen($value2) < 1)
        $data_error_code2 = 4;
      $value3 = $value2 . "	" . $value1;
      array_push($temp_use2,$value3);
      $value = array_pop($temp_use);
    }
    $flush = array_multisort($temp_use2,SORT_NUMERIC);
    $value = array_pop($temp_use2);
    while(strlen($value) > 0)
    {
      $value1 = strtok($value,"	");
      $value2 = strtok("	");
      array_push($locus_names,$value2);
      array_push($locus_values,$value1);
      $flush = settype($value1,"float");
      if($min_coord > $value1)
        $min_coord = $value1;
      if(substr(strtolower($value2),0,4) == "cent")
        $cent_coord = $value1;
      if($max_coord < $value1)
        $max_coord = $value1;
      $value = array_pop($temp_use2);
    }

    if($max_coord == -999)
      $max_coord = $value2;

    if($min_coord > 0)
      $min_coord = 0;

    if($cent_coord == -999)
    {
      $legit_data = false;
      $data_error_code = 3;
    }
  }
  else
  {
    $genetic_map_file = fopen(get_genetic_map_name($chrom,$map),"r");
    $value = trim(fgets($genetic_map_file,1024));    
    while(strlen($value) > 0)
    {
      array_push($temp_use,$value);
      $value = trim(fgets($genetic_map_file,1024));
    }
    $value = array_pop($temp_use);
    while(strlen($value) > 0)
    {
      $value1 = strtok($value,"	");
      $value2 = strtok("	");
      array_push($locus_names,$value1);
      array_push($locus_values,$value2);
      $flush = settype($value2,"float");
      if($min_coord > $value2)
        $min_coord = $value2;
      if(substr(strtolower($value1),0,4) == "cent")
        $cent_coord = $value2;
      if($max_coord < $value2)
        $max_coord = $value2;
      $value = array_pop($temp_use);
    }

    if($max_coord == -999)
      $max_coord = $value2;

    if($min_coord > 0)
      $min_coord = 0;

    if($cent_coord == -999)
    {
      $legit_data = false;
      $data_error_code = 3;
    }
  }

  $cmrn_cm_value = array();
  $cmrn_cmck_value = array();
  $cmrn_um_value = array();

  $cmrn_min = 999;
  $cmrn_max = -999;
  $cmrn_cent = -999;

  $value = trim(fgets($cmrn_file,1024));
  while((strlen($value) > 0) && (!(feof($cmrn_file))))
  {
    $value1 = strtok($value,"	");
    $value2 = strtok("	");
    $value3 = strtok("	");
    $flush = settype($value1,"float");
    $flush = settype($value2,"float");
    $flush = settype($value3,"float");
    if($value2 > $cmrn_max)
      $cmrn_max = $value2;
    if($value2 < $cmrn_min)
      $cmrn_min = $value2;
    if($value1 == 0)
    {
      $cmrn_cent = $value2;
      $cmrn_um_cent = $value3;
    }
    array_push($cmrn_cm_value,$value2);
    array_push($cmrn_cmck_value,$value1);
    array_push($cmrn_um_value,$value3);
    $value = trim(fgets($cmrn_file,1024));
  }

// now, start generating output

  $map_type = $_POST["maptype"];
  if($map_type == "1")
  {
    //echo "<html><head>\n";
?>

<p>The table below shows your input in the first two columns. The third column shows the relative position of each genetic locus as a fraction of map length from the centromere.  This data is used to adjust the genetic map length to fit the RN-cM map (fourth column).  The last three columns show the predicted cytological location of the locus on the chromosome. </p>
<p>To access the maize RN map raw data and related information, visit <a href="http://www.maizegdb.org/RNmaps.php">MaizeGDB</a>.</p>
<?php

    if($cent_coord == -999)
      echo "<p><b><font color=\"red\">Warning!</font></b> It appears as though you did not specify a centromere in your input.  As a result of this, the data generated below is invalid.  Please use the back button on your browser and add a centromere to the map data you've submitted.</p>\n";

    echo "<p>";
    if($map == 1)
      echo "<b>Map:</b> UMC 98<br>\n";
    if($map == 2)
      echo "<b>Map:</b> Genetic<br>\n";
    echo "<b>Chromosome:</b> " . $chrom . "</p>\n";
 
    if($data_error_code2 == 4)
      echo "<p><font color=\"red\"><b>Error!</b></font> The coordinates you submitted are unable to be interpreted.  Possible problems include the possibility that your coordinates are separated from your names by spaces rather than by tabs or that you didn't enter coordinates at all.  Please use the back button and try entering the data again.</p>";
    else
    { 
      echo "<table class='results-table'><tr><td><b><u>Locus</u></b></td><td><b><u>centiMorgan<br>(cM)</u></b></td><td><b><u>As fraction of<br>cM map from<br>centromere</u></b></td><td><b><u>Converted<br>to RN-cM</u></b></td><td><b><u>Corresponding<br>absolute position on<br>SC/chromosome<br>(&micro;m from tip of short arm)</u></b></td><td><b><u>Position as<br>fractional length of<br>arm from centromere<br>(centiMcClintocks)</u></b></td><td><b><u>Arm</u></b></td></tr>";
 
      $locus_name = array_pop($locus_names); 
      while(strlen($locus_name) > 0)
      {
        echo "<tr><td>";
        echo $locus_name;
        echo "</td><td>";
        $locus_value = array_pop($locus_values);
        echo $locus_value;
        echo "</td><td>";

        if($locus_value < $cent_coord)
        {
          $fraction = 1 - (($locus_value - $min_coord) / ($cent_coord - $min_coord));
          $modified_value = ($locus_value - $min_coord) * ($cmrn_cent - $cmrn_min) / ($cent_coord - $min_coord);
        }
        else
        {
          $fraction = ($locus_value - $cent_coord) / ($max_coord - $cent_coord);
          $modified_value4 = $locus_value - $cent_coord;
          $modified_value3 = $modified_value4 / ($max_coord - $cent_coord);
          $modified_value2 = $modified_value3 * ($cmrn_max - $cmrn_cent);
          $modified_value = $modified_value2 + $cmrn_cent;
        }
        printf("%.2f",$fraction);
        echo "</td><td>";
        printf("%.2f",$modified_value);    

        echo "</td><td>";

        $one = $cmrn_cm_value;
        $two = $cmrn_um_value;

        if(substr(strtolower($locus_name),0,4) == "cent")
          printf("%.1f",$cmrn_um_cent);
        else
          printf("%.1f",extract_um_value($locus_name,$modified_value,$one,$two));

        echo "</td><td>";

        printf("%.2f",extract_cmc_value($locus_name,$modified_value,$cmrn_cm_value,$cmrn_cmck_value)); 
        $temp_cmc_value = 100 * extract_cmc_value($locus_name,$modified_value,$cmrn_cm_value,$cmrn_cmck_value);
        echo "&nbsp;(" . $temp_cmc_value . ")";

        echo "</td><td>";
        if(substr(strtolower($locus_name),0,4) == "cent")
          echo "C";
        else if($locus_value < $cent_coord)
          echo "S";
        else
          echo "L";

        echo "</td></tr>\n";

        $locus_name = array_pop($locus_names);
      }  
      echo "</table>";
    }
?>
<?php
    //echo "</td></tr></table>\n";
    //echo "</body></html>";
  }
  else if($map_type == "2")
  {
    $cent_coord = 0.00;
    echo "<html><head><title>Morgan2McClintock Translator - Output</title>\n";
?>
<?php
    //echo "</head><body>\n";
?>
<table border=0 cellpadding=0 cellspacing=0 width="100%">
<tr><td valign="top" rowspan=2 width=150><a href="http://shrimp1.zool.iastate.edu/cmrn/" title="Image courtesy of Ann Lai and Lorrie Anderson"><img border=0 src="sidebar.jpg" width=150 alt="Image courtesy of Ann Lai and Lorrie Anderson"></a></td><td><img src="topbar.jpg" alt="Top cute image"></td></tr>
<tr><td>
<?php

    if($cent_coord == -999)
      echo "<p><b><font color=\"red\">Warning!</font></b> It appears as though you did not specify a centromere in your input.  As a result of this, the data generated below is invalid.  Please use the back button on your browser and add a centromere to the map data you've submitted.</p>\n";

    echo "<table>
<tr><td><b><u>Locus</u></b></td>
<td><b><u>Cytological Coordinate<br>(cMC)</u></b></td>
<td><b><u>Corresponding<br>absolute position on<br>SC/chromosome</u></b></td>
<td><b><u>Converted to cM-<br>cMC map (cM)</u></b></td>
<td><b><u>Arm</u></b></td></tr>";

    $short_arm = true;

    $locus_name = array_pop($locus_names);
    while(strlen($locus_name) > 0)
    {
      echo "<tr><td>";
      echo $locus_name;
      echo "</td><td>";
      $locus_value = array_pop($locus_values);
      echo $locus_value;
      echo "</td><td>";

      $one = $cmrn_cmck_value;
      $two = $cmrn_um_value;

      if(substr(strtolower($locus_name),0,4) == "cent")
        $short_arm = false;

      printf("%.1f",extract_um_value2($locus_name,$locus_value,$one,$two,$short_arm));
      echo "</td><td>";
      printf("%.2f",extract_cm_value($locus_name,$locus_value,$cmrn_cm_value,$cmrn_cmck_value,$short_arm));
      echo "&nbsp;(";
      $cm_temp_value = extract_cm_value($locus_name,$locus_value,$cmrn_cm_value,$cmrn_cmck_value,$short_arm);
      $cm_temp_value = $cm_temp_value * 100;
      echo $cm_temp_value . ")";
      echo "</td><td>";
      if(substr(strtolower($locus_name),0,4) == "cent")
        echo "C";
      else if($short_arm)
        echo "S";
      else
        echo "L";

      echo "</td></tr>\n";
      $locus_name = array_pop($locus_names);
    }
    echo "</table>";
    echo "</td></tr></table>\n";
?>

<?php
    //echo "</body></html>";
  }
  else
  {
?>
<html><head><title>ERROR</title></head><body>ERROR<?php echo $_POST["maptype"]; ?></body></html>
<?php
  }
?>
