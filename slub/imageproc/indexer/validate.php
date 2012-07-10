#!/usr/bin/php
<?php

// Get all namespaces declared in the document.
$_doc = simplexml_load_file($_SERVER['argv'][1]);

$declaredNS = $_doc->getDocNamespaces(TRUE);

// Set default namespaces.
$defaultNS = array (
	'mets' => 'http://www.loc.gov/METS/',
	'mods' => 'http://www.loc.gov/mods/v3',
	'alto' => 'http://www.loc.gov/standards/alto/ns-v2#',
);

// Load document into DOM.
libxml_use_internal_errors(TRUE);

$xml = new DOMDocument('1.0', 'utf-8');

$xml->load($_SERVER['argv'][1]);

$xpath = new DOMXPath($xml);

foreach ($defaultNS as $ns => $uri) {

	$xpath->registerNamespace($ns, $uri);

	$doValidate[$ns] = $xpath->query('//'.$ns.':'.$ns);

}

// Get all schema locations.
$schemaLocations = $xpath->query('//@xsi:schemaLocation');

foreach ($schemaLocations as $schemaLocation) {

	$schemas = explode(' ', $schemaLocation->value);

	for ($i = 0; $i < count($schemas); $i++) {

		if ($schemas[$i] == 'http://www.loc.gov/METS/') {

			$schema['mets'] = $schemas[$i + 1];

		} elseif ($schemas[$i] == 'http://www.loc.gov/mods/v3') {

			$schema['mods'] = $schemas[$i + 1];

		} elseif ($schemas[$i] == 'http://www.loc.gov/standards/alto/ns-v2#') {

			$schema['alto'] = $schemas[$i + 1];

		}

	}

}

// Validate document.
libxml_use_internal_errors(TRUE);

foreach ($doValidate as $ns => $nodes) {

	if ($nodes->length > 0) {

		echo 'Validating '.strtoupper($ns).':'."\n";

		if (!empty($schema[$ns])) {

			$i = 1;

			foreach ($nodes as $node) {

				$part = new DOMDocument('1.0', 'utf-8');

				$part->appendChild($part->importNode($node, TRUE));

				echo '  '.$i.'. '.strtoupper($ns).' part is ';

				if ($part->schemaValidate($schema[$ns])) {

					echo 'valid!'."\n";

				} else {

					echo 'invalid:'."\n";

					libxml_display_errors();

				}

				$i++;

			}

		} else {

			echo '  Error: missing schema!'."\n";

		}

	}

}

// Declare helper functions.
function libxml_display_error($error) {

	$return = '';

	switch ($error->level) {

		case LIBXML_ERR_WARNING:

			$return .= '    Warning '.$error->code.': ';

			break;

		case LIBXML_ERR_ERROR:

			$return .= '    Error '.$error->code.': ';

			break;

		case LIBXML_ERR_FATAL:

			$return .= '    Fatal Error '.$error->code.': ';

			break;

	}

	$return .= trim($error->message);

	if ($error->file) {

		$return .= ' in file '.$error->file;

	}

	$return .= ' on line '.$error->line;

	return $return."\n";

}

function libxml_display_errors() {

	$errors = libxml_get_errors();

	foreach ($errors as $error) {

		echo libxml_display_error($error);

	}

	libxml_clear_errors();

}

?>