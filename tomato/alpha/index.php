<?php
$req_method = $_SERVER['REQUEST_METHOD'];

if ($req_method === 'POST') {
	require __DIR__ . '/data.php';
} else {
	require __DIR__ . '/form.php';
}

