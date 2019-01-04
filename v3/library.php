<?php

function extract_um_value2($locus_name,$modified_value,$cmrn_cmck_value,$cmrn_um_value,$short_arm) {
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

function extract_cm_value($locus_name,$modified_value,$cmrn_cm_value,$cmrn_cmck_value,$short_arm) {
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

function extract_cmc_value($name,$coord,$cmrn_cm_value,$cmrn_cmc_value) {
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


function extract_um_value($name,$coord,$cmrn_cm_value,$cmrn_um_value) {
    $prev_cm_value = array_shift($cmrn_cm_value);
    $curr_cm_value = array_shift($cmrn_cm_value);
    $next_cm_value = array_shift($cmrn_cm_value);
    $prev_um_value = array_shift($cmrn_um_value);
    $curr_um_value = array_shift($cmrn_um_value);
    $return_value = 0.0;

    while(strlen($curr_cm_value) > 0) {
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


function get_cmrn_map_name($chrom) {
    return '../data/cmrn/cmrn' . $chrom;
}

function get_genetic_map_name($chrom,$map) {

    if ($map == 2) {
        return '../data/gen/gen' . $chrom;
    } else if ($map == 1) {

        $prefix = '../data/umc/umc';

        switch($chrom) {
            case 1:
                $fname = 981;
                break;
            case 2:
                $fname = 982;
                break;
            case 3:
                $fname = 983;
                break;
            case 4:
                $fname = 984;
                break;
            case 5:
                $fname = 985;
                break;
            case 6:
                $fname = 986;
                break;
            case 7:
                $fname = 987;
                break;
            case 8:
                $fname = 988;
                break;
            case 9:
                $fname = 989;
                break;
            case 10:
                $fname = 9810;
                break;
            default:
                $fname = 981;
        }
        return $prefix . $fname;

    } else {
        return '';
    }

}

  //function to get RN map name
  function get_rn_map_name($chrom) {
    return '../data/rn/rn' . $chrom;
  }
  
  function geneticToGFF($genetic_records, $chromosome) {
    $gff_records = array();
    $counter = 0;
    $smallestPos = 1000.00;
    $largestPos = 0.00;
    
    foreach($genetic_records as $line){
        
      $line = rtrim($line);
      if($line==""){
        continue;
      }
      $fields = preg_split("/\t/", $line);
      $gff_records[$counter] = "Chr".$chromosome."\t umc98 \t locus \t".$fields[1]."\t".$fields[1]."\t . \t . \t . \t ID=".$fields[0]."\n";
      $smallestTemp = $fields[1];
      $largestTemp = $fields[1];
      
      if($smallestTemp <= $smallestPos){
        $smallestPos = $smallestTemp;
      }
      if($smallestTemp>=$largestPos){
        $largestPos = $largestTemp;
      }
      $counter = $counter + 1;
      
    }
     
     $gff_records[$counter] = "Chr".$chromosome."\t umc98 \t chromosome \t".$smallestPos."\t".$largestPos."\t . \t . \t . \t ID=Chr".$chromosome."\n";
    
    

    return($gff_records);
   }
   
   function cytologicalToGFF($cytological_records, $chromosome){
    $gff_records = array();
    $counter = 0;
    //echo $cytological_records[1];
    foreach($cytological_records as $line){
        
      $line = rtrim($line);
      if($line==""){
        continue;
      }
      $fields = preg_split("/\t/", $line);
      $gff_records[$counter] = "Chr".$chromosome."\t cytological \t locus \t".$fields[1]."\t".$fields[1]."\t . \t . \t . \t ID=".$fields[0]."\n";
      $counter = $counter + 1;
    }
    $gff_records[$counter] = "Chr".$chromosome."\t cytological \t chromosome \t -1.0 \t 1.0 \t . \t . \t . \t ID=".$chromosome." \n";
    return $gff_records;
   }
   
   function RNToGFF($RN_records, $chromosome) {
    $gff_records = array();
    $counter = 0;
    $smallestPos = 0.00;
    $largestPos = 0.00;
    $previousPos = 0;
    foreach($RN_records as $line){
        
      $line = rtrim($line);
      if(strstr($line, "#")!=FALSE){
        continue;
      }
      $fields = preg_split("/\t/", $line);
      $gff_records[$counter] = "Chr".$chromosome ."\t Anderson \t measure \t".$previousPos."\t".$fields[1]."\t . \t . \t . \t value=".(2*$fields[2])."\n";
      $smallestTemp = $fields[1];
      $largestTemp = $fields[1];
      $previousPos = $fields[1];
      
      
      if($smallestTemp>=$largestPos){
        $largestPos = $largestTemp;
      }
      $counter = $counter + 1;
      
    }
     
     $gff_records[$counter] = "Chr".$chromosome." \t Anderson \t chromosome \t".$smallestPos."\t".$largestPos."\t . \t . \t . \t ID=Chr".$chromosome."\n";
    
    

    return($gff_records);
   }
   //end of functions

?>