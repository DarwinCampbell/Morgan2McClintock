<html>
<body>
<table cellpadding=10>
<tr>
<?php
$map_type = $_GET["maptype"];
$current_working_directory = getcwd();

chdir("cvit.b1.2");

// Need to create a unique set of images so we don't have conflicts between concurrent users:
$uid = $_GET["uid"]; //uniqid();


if ($map_type == 1) {
  exec("perl -I . cvit.pl -c config/cvit_genetic.ini -o ../../temp/images/genetic_input_$uid ../../temp/genetic_input_$uid.gff");
  exec("perl -I . cvit.pl -c config/cvit_cytological.ini -o ../../temp/images/cytological_output_$uid ../../temp/cytological_output_$uid.gff");

} else {
  exec("perl -I . cvit.pl -c config/cvit_cytological.ini -o ../../temp/images/cytological_input_$uid ../../temp/cytological_input_$uid.gff");
  exec("perl -I . cvit.pl -c config/cvit_genetic.ini -o ../../temp/images/genetic_output_$uid ../../temp/genetic_output_$uid.gff");
}


exec("perl -I . cvit.pl -c config/cvit_rn.ini -o ../../temp/images/rn_map_$uid ../../temp/rn_data_$uid.gff");
chdir($current_working_directory);

if ($map_type==1){
   echo "<td valign='top'><img src='../temp/images/genetic_input_$uid.png' alt=Genetic_Input /></td>\n";
   echo "<td valign='top'><img src='../temp/images/rn_map_$uid.png' alt=RN_Map /></td>\n";
   echo "<td valign='top'><img src='../temp/images/cytological_output_$uid.png' alt=Cytological_Output /></td>\n";
} else {
   echo "<td valign='top'><img src='../temp/images/cytological_input_$uid.png' alt=Cytological_Input /></td>\n";
   echo "<td valign='top'><img src='../temp/images/rn_map_$uid.png' alt=RN_Map /></td>";
   echo "<td valign='top'><img src='../temp/images/genetic_output_$uid.png' alt=Genetic_Output /></td>\n";
}

?>
</tr>
</table>
</body>
</html>
