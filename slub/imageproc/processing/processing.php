<?php

$bases = array (
//	'/mnt/goobi',
//	'/mnt/goobi2',
//	'/mnt/goobi3',
//	'/mnt/goobi4',
//	'/mnt/goobi5',
	'/mnt/goobi6',
);

$scriptpath = dirname(__FILE__);

foreach ($bases as $base) {

$clients = scandir($base);

unset ($clients[0], $clients[1]);

foreach ( $clients as $client ) {

	$root = $base.'/'.$client;

	chdir($root);

	$directories = glob('*_*');

	$sorted = array ();

	foreach ($directories as $dir) {

		if (is_dir($root.'/'.$dir)
				&& file_exists($root.'/'.$dir.'/'.$dir.'.xml')
				&& !count(glob($root.'/'.$dir.'/processing_*'))
				&& (preg_match('/^.+_[0-9]{8}[0-9A-Z]{1}(-[0-9]+)?(_.+)?$/i', $dir)
					|| preg_match('/^.+_DE-(1a|611)-[0-9]{1,7}_.+$/i', $dir))) {

			exec('touch '.$root.'/'.$dir.'/processing_'.php_uname('n'));

			if (count(glob($root.'/'.$dir.'/processing_*')) == 1
				&& file_exists($root.'/'.$dir.'/processing_'.php_uname('n'))) {

				$sorted[filemtime($root.'/'.$dir.'/'.$dir.'.xml')] = $dir;

			} else {

				foreach (glob($root.'/'.$dir.'/processing_*') as $processing) {

					$con[filemtime($processing)] = $processing;

				}

				ksort($con, SORT_NUMERIC);

				if ($con[0] === $root.'/'.$dir.'processing_'.php_uname('n')) {

					$sorted[filemtime($root.'/'.$dir.'/'.$dir.'.xml')] = $dir;

				}

			}

		}

		if (count($sorted) == 5) break;

	}

	ksort($sorted, SORT_NUMERIC);

	sleep(30);

	while ($directory = array_shift($sorted)) {

		if (!empty($directory)
				&& is_dir($root.'/'.$directory)
				&& !file_exists($root.'/'.$directory.'/ready-for-indexing')
				&& !is_dir($root.'/'.$directory.'/'.$directory.'_tif/jpegs')) {

			echo "Processing directory: $root/$directory...\n";

			$tiles = explode('_', $directory);

			unset ($ppn);

			foreach ($tiles as $tile) {

				if (preg_match('/^[0-9]{8}[0-9A-Z]{1}(-[0-9]+)?$/i', $tile)
						|| preg_match('/^DE-(1a|611)-[0-9]{1,7}$/i', $tile)) {

					$ppn = $tile;

					break;

				}

			}

			if (!empty($ppn)
					&& !is_dir($root.'/'.$directory.'/'.$directory.'_tif')) {

				echo "No TIFFs available, but XML metadata found. Doing nothing...\n";

				exec('chown -R root.root '.$root.'/'.$directory.'/');

				exec('chmod 644 '.$root.'/'.$directory.'/'.$directory.'.xml');

				exec('touch '.$root.'/'.$directory.'/ready-for-indexing');

				echo "Done!\n";

			} elseif (!empty($ppn)
					&& is_dir($root.'/'.$directory.'/'.$directory.'_tif')) {

				echo "TIFFs and XML metadata found. Doing full image processing...\n";

				$lock = $root.'/'.$directory;

				exec('chown -R root.root '.$lock.'/');

				exec('chmod 755 '.$lock.'/');

				exec('chmod 755 '.$lock.'/'.$directory.'_tif/');

				exec('mkdir -m777 '.$lock.'/'.$directory.'_tif/jpegs');

				$xml = @simplexml_load_file($lock.'/'.$directory.'.xml');

				$xml->registerXPathNamespace('mets', 'http://www.loc.gov/METS/');

				$xml->registerXPathNamespace('mods', 'http://www.loc.gov/mods/v3');

				$xml->registerXPathNamespace('slub', 'http://slub-dresden.de/');

				$_footer = $xml->xpath('//slub:footer');

				if (!empty($_footer[0])) {

					$footer = (string) $_footer[0];

				} else {

					$footer = $client;

				}
				
				$_processId = $xml->xpath('//mets:fileGrp[@USE="LOCAL"]/mets:file/mets:FLocat');

				if (!empty($_processId[0])) {

					$processId = explode('/', (string) $_processId[0]->attributes('http://www.w3.org/1999/xlink')->href);
					
					$processId = $processId[5];
										
				} else {
					
					$processId = 0;
					
				}
				
				unset ($tiffs);

				$tiffs = scandir($lock.'/'.$directory.'_tif');

				$i = 0;

				foreach ($tiffs as $tiff) {

					if (is_file($lock.'/'.$directory.'_tif/'.$tiff)
							&& preg_match('/^[0-9]{8}\.tif$/', $tiff)) {

						$i++;

						exec('convert '.$lock.'/'.$directory.'_tif/'.$tiff.' -quiet -quality 75 -strip '.$lock.'/'.$directory.'_tif/jpegs/'.$tiff.'.original.jpg');

						exec('convert '.$lock.'/'.$directory.'_tif/jpegs/'.$tiff.'.original.jpg -scale 500 -quality 75 -strip '.$lock.'/'.$directory.'_tif/jpegs/'.$tiff.'.small.jpg');

						exec('montage '.$lock.'/'.$directory.'_tif/jpegs/'.$tiff.'.small.jpg '.$scriptpath.'/images/'.$footer.'_500.gif -tile 1x2 -geometry +0+0 -quality 75 '.$lock.'/'.$directory.'_tif/jpegs/'.$tiff.'.small.jpg');

						exec('convert '.$lock.'/'.$directory.'_tif/jpegs/'.$tiff.'.small.jpg -gravity southeast -stroke none -fill black -annotate +0+25 \'http://digital.slub-dresden.de/id'.$ppn.'/'.$i.'\' -quality 75 '.$lock.'/'.$directory.'_tif/jpegs/'.$tiff.'.small.jpg');

						exec('convert '.$lock.'/'.$directory.'_tif/jpegs/'.$tiff.'.original.jpg -scale 1000 -quality 75 -strip '.$lock.'/'.$directory.'_tif/jpegs/'.$tiff.'.medium.jpg');

						exec('montage '.$lock.'/'.$directory.'_tif/jpegs/'.$tiff.'.medium.jpg '.$scriptpath.'/images/'.$footer.'_1000.gif -tile 1x2 -geometry +0+0 -quality 75 '.$lock.'/'.$directory.'_tif/jpegs/'.$tiff.'.medium.jpg');

						exec('convert '.$lock.'/'.$directory.'_tif/jpegs/'.$tiff.'.medium.jpg -gravity south -stroke none -fill white -annotate +25+25 \'http://digital.slub-dresden.de/id'.$ppn.'/'.$i.'\' -quality 75 '.$lock.'/'.$directory.'_tif/jpegs/'.$tiff.'.medium.jpg');

						exec('convert '.$lock.'/'.$directory.'_tif/jpegs/'.$tiff.'.medium.jpg -strip -quality 75 '.$lock.'/'.$directory.'_tif/jpegs/'.$tiff.'.pdf');

						exec('convert '.$lock.'/'.$directory.'_tif/jpegs/'.$tiff.'.original.jpg -scale 2000 -quality 75 -strip '.$lock.'/'.$directory.'_tif/jpegs/'.$tiff.'.large.jpg');

						exec('montage '.$lock.'/'.$directory.'_tif/jpegs/'.$tiff.'.large.jpg '.$scriptpath.'/images/'.$footer.'_2000.gif -tile 1x2 -geometry +0+0 -quality 75 '.$lock.'/'.$directory.'_tif/jpegs/'.$tiff.'.large.jpg');

						exec('convert '.$lock.'/'.$directory.'_tif/jpegs/'.$tiff.'.large.jpg -gravity south -stroke none -fill white -annotate +50+50 \'http://digital.slub-dresden.de/id'.$ppn.'/'.$i.'\' -quality 75 '.$lock.'/'.$directory.'_tif/jpegs/'.$tiff.'.large.jpg');

						exec('convert '.$lock.'/'.$directory.'_tif/jpegs/'.$tiff.'.original.jpg -scale 150x150 -strip -quality 75 '.$lock.'/'.$directory.'_tif/jpegs/'.$tiff.'.thumbnail.jpg');

					}

				}

				exec('cd '.$lock.'/'.$directory.'_tif/jpegs && pdftk *.pdf cat output '.$ppn.'.pdf');

				exec('cd '.$lock.' && ln -sf '.$directory.'_tif '.$ppn.'_tif');

				exec('mkdir -p /mnt/lza/'.$processId.'/images/scans_tif');
				
				exec('cd '.$lock.'/'.$directory.'_tif && mv -fu *.tif /mnt/lza/'.$processId.'/images/scans_tif/');

				exec('mkdir -p /mnt/lza/'.$processId.'/ocr/'.$directory.'_xml');
				
				exec('cd '.$lock.'/'.$directory.'_xml && cp -fu *.xml /mnt/lza/'.$processId.'/ocr/'.$directory.'_xml/');

				exec('cd '.$lock.' && ln -sf '.$directory.'_xml '.$ppn.'_ocr');

				exec('cd '.$lock.' && rm -rf '.$directory.'_abbyy');

				exec('cd '.$lock.' && rm -rf '.$directory.'_alto');

				exec('touch '.$lock.'/ready-for-indexing');

				echo "Done!\n";

			}

		}

	}

}

}

?>