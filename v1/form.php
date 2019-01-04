<?php require("../php_includes/form_header_text.html"); ?>

<form method="post">
<input type="hidden" name="maptype" value="1">
<p><b>Step 1:</b> Select a chromosome: 
<select name="chrom">
    <option value=1>1</option>
    <option value=2>2</option>
    <option value=3>3</option>
    <option value=4>4</option>
    <option value=5>5</option>
    <option value=6>6</option>
    <option value=7>7</option>
    <option value=8>8</option>
    <option value=9>9</option>
    <option value=10>10</option>
</select></p>

<p><b>Step 2:</b> Select a map to use... <select name="map">
<option value=0>---
<option value=1>UMC 98 (genetic)
<option value=2>Genetic (see note)
</select> <input type="submit" value="Calculate!"><br>
... or paste your genetic map into the following space.<br>
<textarea name="coords" rows=12 cols=100></textarea><br>
<input type="submit" value="Calculate!"> <input type="reset" value="Clear!"></form>

<?php require("../php_includes/submit_your_own_data_map.html"); ?>
<?php require("../php_includes/genetic_sample.html"); ?>

<p><b>Note About the Genetic Map Dataset:</b> Centromeres have artificially been added to this map based on recombination data from Ed Coe.</p>


