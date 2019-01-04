<html><head>
<link rel="stylesheet" type="text/css" href="/assets/style.css" Title="TOCStyle">
<title>Morgan2McClintock Translator</title>
</head>

<table border=0 cellpadding=0 cellspacing=0 width="100%">
<tr><td valign="top" rowspan=2 width=150>
<a href="http://shrimp1.zool.iastate.edu/cmrn/" title="Image courtesy of Ann Lai and Lorrie Anderson"><img border=0 src="/assets/sidebar.jpg" width=150 alt="Image courtesy of Ann Lai and Lorrie Anderson"></a></td><td><img src="/assets/topbar.jpg" alt="Top cute image"></td></tr>
<tr>

<td class="main-content">
<?php
$req_method = $_SERVER['REQUEST_METHOD'];

if ($req_method === 'POST') {
	require __DIR__ . '/data.php';
} else {
	require __DIR__ . '/form.php';
}

?>

<p><b>Comments or questions?</b> Send an email to Carolyn Lawrence at <a href="mailto:triffid@iastate.edu">triffid@iastate.edu</a>.</p>

</td>
</tr>
</table>
</body></html>