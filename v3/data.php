<p>The table below shows your input in the first two columns. The third 
        column shows the relative position of each genetic locus as a fraction 
        of map length from the centromere.  This data is used to adjust the 
        genetic map length to fit the RN-cM map (fourth column).  The last 
        three columns show the predicted cytological location of the locus on 
        the chromosome. 
      </p>
      <p>To access the maize RN map raw data and related information, visit 
        <a href="http://www.maizegdb.org/RNmaps.php">MaizeGDB</a>.
      </p>


<?php
require './library.php';
// Used to write unique files to the temp dir on disk:
$uid = uniqid();

// Kludge to clear any old generated images from disk:
exec("python ../clean_old_visualizations.py"); 
   
   //main code
  $chrom    = $_POST["chrom"];
  $map      = $_POST["map"];
  $coords   = trim($_POST["coords"]);
  $map_type = $_POST["maptype"];

  //print("<h1>$map_type</h1>");

  $legit_data = true;

  $RN_records = file(get_rn_map_name($chrom));
  $gff_records_rn = RNToGFF($RN_records, $chrom);
  //$fileToWriteInputTo = "/var/www/html/lawrencelab/Morgan2McClintock/Version3.0/temp/rn_data.gff";

   $output_path = "../temp/rn_data_$uid.gff";

  $fh = fopen($output_path, "w");
    foreach($gff_records_rn as $record) {
       fwrite($fh, $record);
    }
    fclose($fh);
  
  $cmrn_map_name = get_cmrn_map_name($chrom);
  if(strlen($cmrn_map_name) == 0) {
    $legit_data = false;
    $data_error_code = 1;
  }

  $locus_names  = array();
  $locus_values = array();
  $temp_use     = array();
  $temp_use2    = array();
  $temp_use3    = array();

  $min_coord  = 999;
  $max_coord  = -999;
  $cent_coord = -999;

  $cmrn_file = fopen($cmrn_map_name,"r");

  if(($map == 0) && (strlen($coords) == 0)) {
    $legit_data = false;
    $data_error_code = 2;
  } else if(strlen($coords) > 0) {
    $value = trim(strtok($coords,"\n"));
    while(strlen($value) > 0) {
      array_push($temp_use,$value);
      $value = strtok("\n");
    }
    $temp_use3 = $temp_use;
    $value = array_pop($temp_use);
    while(strlen($value) > 0) {
      $value1 = strtok($value,"	");
      $value2 = strtok("	");
      if(strlen($value2) < 1)
        $data_error_code2 = 4;
      $value3 = $value2 . "	" . $value1;
      array_push($temp_use2,$value3);
      $value = array_pop($temp_use);
    }
    if($_POST["maptype"] != "2")
      $flush = array_multisort($temp_use2,SORT_NUMERIC);
    else
      $temp_use2 = array_reverse($temp_use2);
    $value = array_pop($temp_use2);

    while(strlen($value) > 0) {
      $value1 = strtok($value,"	");
      $value2 = strtok("	");
      array_push($locus_names,$value2);
      if(($value1 > 1) && ($map_type == "2"))
        $value1 = $value1 / 100;

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

    if($cent_coord == -999) {
      $legit_data = false;
      $data_error_code = 3;
    }
  } else {
    
    $genetic_map_file = fopen(get_genetic_map_name($chrom, $map), "r");
    $value = trim(fgets($genetic_map_file,1024));    
    while(strlen($value) > 0) {
      array_push($temp_use,$value);
      $value = trim(fgets($genetic_map_file,1024));
    }
    $value = array_pop($temp_use);
    while(strlen($value) > 0) {
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

    if($cent_coord == -999) {
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
  while((strlen($value) > 0) && (!(feof($cmrn_file)))) {
    $value1 = strtok($value,"	");
    $value2 = strtok("	");
    $value3 = strtok("	");
    $flush = settype($value1, "float");
    $flush = settype($value2, "float");
    $flush = settype($value3, "float");
    if($value2 > $cmrn_max)
      $cmrn_max = $value2;
    if($value2 < $cmrn_min)
      $cmrn_min = $value2;
    if($value1 == 0) {
      $cmrn_cent = $value2;
      $cmrn_um_cent = $value3;
    }

    array_push($cmrn_cm_value, $value2);
    array_push($cmrn_cmck_value, $value1);
    array_push($cmrn_um_value, $value3);
    $value = trim(fgets($cmrn_file, 1024));
  }


////////////////////////////////////////////////////////////////////////////////
// now, start generating output

  // Input is genetic map
  if ($map_type == "1") {
    if ($coords != "") {

      /*
      print("WHAT IS COORDS?<br>");
      var_dump($coords);
      print("<br>");
      $toks = strtok($coords, "\n");
      print("<br>");
      var_dump($toks);
      print("<br>");
      var_dump($toks);
      */
      $lines = explode("\n", trim($coords));

    } else {

      $lines = file(get_genetic_map_name($chrom, $map));
    }
    
    //generate GFF file for use of CViT to create image of the genetic input
    $gff_records_gen = geneticToGFF($lines, $chrom);
    
    //$fileToWriteInputTo = "/var/www/html/lawrencelab/Morgan2McClintock/Version3.0/temp/genetic_input.gff";
    $output_path = "../temp/genetic_input_$uid.gff";
    $fh = fopen($output_path, "w");
    foreach($gff_records_gen as $record) {
       fwrite($fh, $record);
    }
    fclose($fh);



    if($cent_coord == -999)
      echo "<p><b><font color=\"red\">Warning!</font></b> It appears as though you did 
        not specify a centromere in your input.  As a result of this, the data 
        enerated below is invalid.  Please use the back button on your browser 
        and add a centromere to the map data you've submitted.
      </p>\n";

    echo "<p>";
      
    echo "<strong>Map:</strong> ";
    if ($map_type == 1) echo "UMC 98";
    if ($map_type == 2) echo "Genetic";
    echo "<br />\n";
    echo "<strong>Chromosome:</strong> $chrom</p>\n";
 
    if ($data_error_code2 == 4) {
      echo "<p>
        <font color=\"red\"><b>Error!</b></font> The coordinates you submitted 
        are unable to be interpreted.  Possible problems include the 
        possibility that your coordinates are separated from your names by 
        spaces rather than by tabs or that you didn't enter coordinates at 
        all. Please use the back button and try entering the data again.
      </p>";
    
    }  else {
      // This is the table for genetic maps:
      echo "<table class='results-table'>
        <tr>
          <td>
            <b><u>Locus</u></b></td><td><b><u>centiMorgan<br>(cM)</u></b>
          </td>
          <td>
            <b><u>As fraction of<br>cM map from<br>centromere</u></b>
          </td>
          <td>
            <b><u>Converted<br>to RN-cM</u></b>
          </td>
          <td>
            <b><u>Corresponding<br>absolute position on<br>SC/chromosome<br>
            (&micro;m from tip of short arm)</u></b></td><td><b><u>Position 
            as<br>fractional length of<br>arm from centromere<br>
            (centiMcClintocks)</u></b>
          </td>
          <td>
            <b><u>Arm</u></b>
          </td>
        </tr>";
 
      
      //$fileToWriteOutputTo = "/var/www/html/lawrencelab/Morgan2McClintock/Version3.0/temp/cytological_output.gff";
      $output_path = "../temp/cytological_output_$uid.gff";
      $fh2 = fopen($output_path, "w");
      
      $locus_name = array_pop($locus_names);
      while(strlen($locus_name) > 0)
      {
        echo "<tr>\n";
        
        echo "<td>$locus_name</td>\n";
        $locus_value = array_pop($locus_values);
        echo "<td>$locus_value</td>\n";

        if($locus_value < $cent_coord)
        {
          $fraction = 1 - ($locus_value / ($cent_coord - $min_coord));
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
        printf("<td>%.2f</td>\n", $fraction);
        //echo "</td>";
        printf("<td>%.2f</td>\n", $modified_value);    

        $one = $cmrn_cm_value;
        $two = $cmrn_um_value;

        echo "<td>";
        if(substr(strtolower($locus_name), 0, 4) == "cent") {
          printf("%.1f",$cmrn_um_cent);
        
        } else {
          printf("%.1f",extract_um_value($locus_name,$modified_value,$one,$two));
        }

        echo "</td>\n<td>";
        printf("%.2f", extract_cmc_value($locus_name, $modified_value, $cmrn_cm_value, $cmrn_cmck_value)); 
        $temp_cmc_value = 100 * extract_cmc_value($locus_name, $modified_value, $cmrn_cm_value, $cmrn_cmck_value);
        echo " (" . $temp_cmc_value . ")</td>\n";
        $temp_cmc_value = ($temp_cmc_value)/100;
        
        echo "<td>";
        
        if(substr(strtolower($locus_name),0,4) == "cent")
          echo "C";
        else if($locus_value < $cent_coord){
          echo "S";
          $temp_cmc_value = (-1*$temp_cmc_value);
        }
        else
          echo "L";
          
        echo "</td>\n</tr>\n";
        
        //String for GFF file 
        $cytological_output_string = "Chr".$chrom."\t tMorgan2McClintock \t locus \t".$temp_cmc_value."\t".$temp_cmc_value."\t.\t.\t.\t ID=".$locus_name."\n";
        fwrite($fh2, $cytological_output_string);
        //String wrote to GFF file
        
        $locus_name = array_pop($locus_names);
      }
      $chromosome_string = "Chr".$chrom."\t tMorgan2McClintock \t chromosome \t -1.0 \t 1.0 \t.\t.\t.\t ID=Chr".$chrom."\n";
      fwrite($fh2, $chromosome_string);
      fclose($fh2);
      echo "</table>\n";
    }
    echo "<br/><a href='cvit_picture_maker.php?maptype=1&uid=$uid' target='_blank'>Click here for a visual display of the two correlated maps of this chromosome </a><br/>";



  } else if($map_type == "2") {
  // Input is cytological map
  
    $cent_coord = 0.00;
    $lines = explode("\n", $coords);
    //var_dump($lines);
    
    //generate GFF file for use of CViT to create image of cytological input
    $gff_records = cytologicalToGFF($lines, $chrom);
    //$fileToWriteInputTo = "/var/www/html/lawrencelab/Morgan2McClintock/Version3.0/temp/cytological_input.gff";
    $fileToWriteInputTo = "../temp/cytological_input_$uid.gff";
    $fh = fopen($fileToWriteInputTo, "w");
    foreach($gff_records as $record){
       fwrite($fh, $record);
    }
    fclose($fh);
    
    if($cent_coord == -999)
      echo "
      <p><b><font color=\"red\">Warning!</font></b> It appears as though you did 
        not specify a centromere in your input.  As a result of this, the data 
        generated below is invalid.  Please use the back button on your browser 
        and add a centromere to the map data you've submitted.
      </p>\n";

    $mult_factor = $_POST["factor"];
    $flush = settype($mult_factor, "float");
    // This is the cytological map table only:
    echo "<table class='results-table'>
      <tr>
        <td><b><u>Locus</u></b></td>
        <td><b><u>Position As<br>Fractional Length of Arm<br>(cMC)</u></b></td>
        <td><b><u>Corresponding<br>absolute position on<br>SC/chromosome</u></b></td>
        <td><b><u>Calculated cM map<br>coordinates</u></b></td>
        <td><b><u>cM map with<br />conversion factor=$mult_factor</u></b></td>
        <td><b><u>Arm</u></b></td>
      </tr>";
    $short_arm = true;

    //$fileToWriteOutputTo = "/var/www/html/lawrencelab/Morgan2McClintock/Version3.0/temp/genetic_output.gff";
    $fileToWriteOutputTo = "../temp/genetic_output_$uid.gff";
    $fh2 = fopen($fileToWriteOutputTo, "w");
      
    //for finding ends of chromosomes for CViT display  
    $smallest_cm_value = 1000.00;
    $largest_cm_value = 0.00;
    
    $locus_name = array_pop($locus_names);
    while(strlen($locus_name) > 0) {
      echo "<tr>\n<td>$locus_name</td>\n";
      $locus_value = array_pop($locus_values);
      echo "<td>$locus_value (" . ($locus_value * 100) . ")</td>\n";

      $one = $cmrn_cmck_value;
      $two = $cmrn_um_value;

      if(substr(strtolower($locus_name),0,4) == "cent")
        $short_arm = false;

      $flush = settype($mult_factor,"float");
      if($mult_factor <= 0)
        $mult_factor = 1;

      //echo "<td>";
      printf("<td>%.1f</td>", extract_um_value2($locus_name, $locus_value, $one, $two, $short_arm));

      $ult_cm_value = extract_cm_value($locus_name, $locus_value, $cmrn_cm_value, $cmrn_cmck_value, $short_arm);
      printf("<td>%.2f</td>\n", $ult_cm_value);
      
      //check for smallest and largest values of loci on genetic map for CViT
      if($ult_cm_value < $smallest_cm_value){
        $smallest_cm_value = $ult_cm_value;
      }
      if($ult_cm_value > $largest_cm_value){
        $largest_cm_value = $ult_cm_value;
      }
      
      //String for GFF file 
      $genetic_output_string = "Chr$chrom\ttMorgan2McClintock\tlocus\t$ult_cm_value\t$ult_cm_value\t.\t.\t.\tID=$locus_name\n";
      fwrite($fh2, $genetic_output_string);
      //String wrote to GFF file
        
      
      printf("<td>%.2f</td>\n", $ult_cm_value * $mult_factor);

      echo '<td>';

      if(substr(strtolower($locus_name), 0, 4) == "cent")
        echo "C";
      else if($short_arm)
        echo "S";
      else
        echo "L";

      echo "</td>\n</tr>\n";
      $locus_name = array_pop($locus_names);
    }

    $chromosome_string = "Chr".$chrom."\t tMorgan2McClintock \t chromosome \t".$smallest_cm_value."\t".$largest_cm_value."\t.\t.\t.\t ID=".$chrom."\n";
    fwrite($fh2, $chromosome_string);
    fclose($fh2);
    echo "</table>\n";
    echo "<br/><a href='cvit_picture_maker.php?maptype=2&uid=$uid' target='_blank'>Click here for a visual display of the two correlated maps of this chromosome</a><br/>";

} else {
  print("ERROR");
}
?>

