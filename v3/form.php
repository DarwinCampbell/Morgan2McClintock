      <?php require("../php_includes/form_header_text.html"); ?>

      <form method="post">
        <p><b>Step 1:</b> Select a chromosome: 
        <select name="chrom">
          <option value=1>1
          <option value=2>2
          <option value=3>3
          <option value=4>4
          <option value=5>5
          <option value=6>6
          <option value=7>7
          <option value=8>8
          <option value=9>9
          <option value=10>10
        </select>
        </p>

        <p><b>Step 2:</b> Select a map to use... 
        <select name="map">
          <option value=0>---</option>
          <option value=1>UMC 98 (genetic)</option>
          <option value=2>Genetic (see note)</option>

        </select><br>
        ... or paste your map into the following space.  
        <b>What type of map is it?</b> 
        <select name="maptype">
          <option value="1">genetic
          <option value="2">cytological
        </select> 
        <br>
        You may want to put in a <a href="#factor">conversion factor</a> for 
        cytological map translations: 
        <input type="text" size=5 name="factor" value="1.0"><br>
        Also, see this <a href="#note">important note</a> about adding your own 
        map.<br>
        <textarea name="coords" rows=12 cols=100></textarea><br>
        <input type="submit" value="Calculate!">
      </form>

        <?php require("../php_includes/submit_your_own_data_map.html"); ?>
        <?php require("../php_includes/genetic_sample.html"); ?>
        <?php require("../php_includes/cytogenetic_sample.html"); ?>
      <p><strong>Note About the Genetic Map Dataset:</strong> Centromeres have artificially been added to this map based on recombination data from Ed Coe.

      <p><a name="factor"></a><b>Note About Conversion Factor:</b> Entering a 
        number in this box causes the resulting genetic map to be amplified by 
        that factor in order to aid in matching the output to other genetic maps 
        you may have.
      </p>
