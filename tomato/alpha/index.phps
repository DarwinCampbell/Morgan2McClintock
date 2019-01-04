<html><head>
<link REL="STYLESHEET" TYPE="text/css"
HREF="style.css" Title="TOCStyle">
<title>Morgan2McClintock Translator v. 2.0</title></head>
<table border=0 cellpadding=0 cellspacing=0 width="100%">
<tr><td valign="top" rowspan=2 width=150><a href="." title="Image courtesy of Ann Lai and Lorrie Anderson"><img border=0 src="sidebar.jpg" width=150 alt="Image courtesy of Ann Lai and Lorrie Anderson"></a></td><td><img src="topbar.jpg" alt="Top cute image"></td></tr>
<tr><td>
<p>This tool uses the tomato Recombination Nodule map to calculate approximate chromosomal positions for loci given a genetic map for a single chromosome.  To run the calculator on your own machine, visit the <a href="download.php">download page</a>).</p>

<form method="post" action="data.php">
<p><b>Step 1:</b> Select a chromosome: <select name="chrom">
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
<option value=11>11
<option value=12>12
</select></p>

<p><b>Step 2:</b> Select a map to use... <select name="map">
<option value=0>---
<option value=1>EXPEN 2000 (genetic)
</select> (EXPEN 2000 centromeres were mathematically estimated placed with help from SGD)<br>
... or paste your map into the following space.  <b>What type of map is it?</b> <select name="maptype"><option value="1">genetic<option value="2">cytological</select> 
<br>
You may want to put in a <a href="#factor">conversion factor</a> for cytological map translations: <input type="text" size=5 name="factor" value="1.0"><br>
Also, see this <a href="#note">important note</a> about adding your own map.<br>
<textarea name="coords" rows=12 cols=100></textarea><br>
<input type="submit" value="Calculate!"></form>

<p><a name="note"></a><b>How To Submit Your Own Map Data</b>:<br>
Your map data MUST include the following:<br>
(1) Your map must consist of a number of lines.  Each line should start with the name of the locus, followed by a tab, followed by the cytological or centimorgan value for that locus.<br>
(2) The program assumes that the tip of the short arm for genetic maps is at 0.0 cM UNLESS you submit a locus with a cM value of less than zero; it assumes that the tip of the short arm for a cytological map is at 1.00.<br>
(3) The program also assumes that the tip of the long arm on genetic maps is at the cM value of your highest submitted cM value.  So, if you believe that the tip is not exactly at this locus, you should add a tip1 locus at the end with the cM value of where you believe the tip to be.<br>
(4) There must be ONE locus beginning with the characters "cent" for all maps (on cytogenetic maps, this would likely be with a coordinate of 0; it is needed to mark the separation between short and long arm).  The program will assume that this is the centromere.<br>
(5) <b>For cytogenetic maps</b>, your loci must be in order starting with the tip of the short arm.</p>

<p>Here is a genetic map sample set to use while experimenting.  Assume that this set is for chromosome #1.</p>

<pre>
SSR478	0
cent1	32.7
CT81	47.7
T1327	90
T0141	129
SSR595	147
T1612	150
T1679	165
</pre>

<p><a name="factor"></a><b>Note About Conversion Factor:</b> Entering a number in this box causes the resulting genetic map to be amplified by that factor in order to aid in matching the output to other genetic maps you may have.</p>

<p><b>Comments or questions?</b> Send an email to Carolyn Lawrence at <a href="mailto:triffid@iastate.edu">triffid@iastate.edu</a>.</p>

</td></tr></table>
</body></html>
