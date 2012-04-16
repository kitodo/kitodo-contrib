<?php

$bases = array (
	'/mnt/goobi',
	'/mnt/goobi2',
	'/mnt/goobi3',
	'/mnt/goobi4',
);

$scriptpath = dirname(__FILE__);

foreach($bases as $base) {

$clients = scandir( $base );

unset( $clients[0], $clients[1] );

foreach( $clients as $client ) {

	$root = $base.'/'.$client;

	$directories = scandir( $root );

	$sorted = array ();

	foreach( $directories as $dir ) {

		if( is_dir( $root . '/' . $dir ) && file_exists( $root . '/' . $dir . '/' . $dir . '.xml' ) && !file_exists( $root . '/' . $dir . '/processing' ) && ( preg_match( '/^.+_[0-9]{8}[0-9LXYZ]{1}(-[0-9]+)?$/i', $dir ) || preg_match( '/^.+_[0-9]{8}[0-9LXYZ]{1}(-[0-9]+)?_.+$/i', $dir ) ) ) {

			exec( 'touch ' . $root . '/' . $dir . '/processing' );

			$sorted[filemtime( $root . '/' . $dir . '/' . $dir . '.xml' )] = $dir;

		}

		if (count($sorted) == 50) break;

	}

	ksort( $sorted, SORT_NUMERIC );

	sleep(30);

	while ($directory = array_shift( $sorted )) {

		if( !empty( $directory ) && is_dir( $root . '/' . $directory ) && !file_exists( $root . '/' . $directory . '/ready-for-indexing' ) && !is_dir( $root . '/' . $directory . '/' . $directory . '_tif/jpegs' ) ) {

			echo "Processing directory: $root/$directory...\n";

			$tiles = explode( '_', $directory );

			unset( $ppn );

			foreach( $tiles as $tile ) {

				if( preg_match( '/^[0-9]{8}[0-9LXYZ]{1}(-[0-9]+)?$/i', $tile ) ) {

					$ppn = $tile;

					break;

				}

			}

			unset( $output );

			$output = array();

			if( !empty( $ppn ) && !is_dir( $root . '/' . $directory . '/' . $directory . '_tif' ) ) {

				echo "No TIFFs available, but XML metadata found. Doing nothing...\n";

				exec( 'chown -R root.root ' . $root . '/' . $directory . '/', $output );

				exec( 'chmod 644 ' . $root . '/' . $directory . '/' . $directory . '.xml', $output );

				exec( 'touch ' . $root . '/' . $directory . '/ready-for-indexing', $output );

				if( !empty( $output ) ) {

					echo '  '.implode( "\n  ", $output )."\n";

				}

				echo "Done!\n";

			} elseif( !empty( $ppn ) && is_dir( $root . '/' . $directory . '/' . $directory . '_tif' ) ) {

				echo "TIFFs and XML metadata found. Doing full image processing...\n";

				$lock = $root . '/' . $directory;

				exec( 'chown -R root.root ' . $lock . '/', $output );

				exec( 'chmod 755 ' . $lock . '/', $output );

				exec( 'chmod 755 ' . $lock . '/' . $directory . '_tif/', $output );

				exec( 'mkdir -m777 ' . $lock . '/' . $directory . '_tif/jpegs', $output );

				$xml = @simplexml_load_file( $lock . '/' . $directory . '.xml' );

				$xml->registerXPathNamespace('mets', 'http://www.loc.gov/METS/');

				$xml->registerXPathNamespace('mods', 'http://www.loc.gov/mods/v3');

				$xml->registerXPathNamespace('slub', 'http://slub-dresden.de/');

				$_footer = $xml->xpath('//slub:footer');

				if (!empty($_footer[0])) {

					$footer = (string) $_footer[0];

				} else {

					$footer = $client;

				}

				unset( $tiffs );

				$tiffs = scandir( $lock . '/' . $directory . '_tif' );

				$i = 0;

				foreach( $tiffs as $tiff ) {

					if( is_file( $lock . '/' . $directory . '_tif/' . $tiff ) && preg_match( '/^[0-9]{8}\.tif$/', $tiff ) ) {

						$i++;

						exec( 'convert ' . $lock . '/' . $directory . '_tif/' . $tiff . ' -quiet -quality 75 -strip ' . $lock . '/' . $directory . '_tif/jpegs/' . $tiff . '.original.jpg', $output );

						exec( 'convert ' . $lock . '/' . $directory . '_tif/jpegs/' . $tiff . '.original.jpg -scale 500 -quality 75 -strip ' . $lock . '/' . $directory . '_tif/jpegs/' . $tiff . '.small.jpg', $output );

						exec( 'montage ' . $lock . '/' . $directory . '_tif/jpegs/' . $tiff . '.small.jpg ' . $scriptpath . '/images/' . $footer . '_500.gif -tile 1x2 -geometry +0+0 -quality 75 ' . $lock . '/' . $directory . '_tif/jpegs/' . $tiff . '.small.jpg', $output );

						exec( 'convert ' . $lock . '/' . $directory . '_tif/jpegs/' . $tiff . '.small.jpg -gravity southeast -stroke none -fill black -annotate +0+25 \'http://digital.slub-dresden.de/id' . $ppn . '/' . $i . '\' -quality 75 ' . $lock . '/' . $directory . '_tif/jpegs/' . $tiff . '.small.jpg', $output );

						exec( 'convert ' . $lock . '/' . $directory . '_tif/jpegs/' . $tiff . '.original.jpg -scale 1000 -quality 75 -strip ' . $lock . '/' . $directory . '_tif/jpegs/' . $tiff . '.medium.jpg', $output );

						exec( 'montage ' . $lock . '/' . $directory . '_tif/jpegs/' . $tiff . '.medium.jpg ' . $scriptpath . '/images/' . $footer . '_1000.gif -tile 1x2 -geometry +0+0 -quality 75 ' . $lock . '/' . $directory . '_tif/jpegs/' . $tiff . '.medium.jpg', $output );

						exec( 'convert ' . $lock . '/' . $directory . '_tif/jpegs/' . $tiff . '.medium.jpg -gravity south -stroke none -fill white -annotate +25+25 \'http://digital.slub-dresden.de/id' . $ppn . '/' . $i . '\' -quality 75 ' . $lock . '/' . $directory . '_tif/jpegs/' . $tiff . '.medium.jpg', $output );

						exec( 'convert ' . $lock . '/' . $directory . '_tif/jpegs/' . $tiff . '.medium.jpg -strip -quality 75 ' . $lock . '/' . $directory . '_tif/jpegs/' . $tiff . '.pdf', $output );

						exec( 'convert ' . $lock . '/' . $directory . '_tif/jpegs/' . $tiff . '.original.jpg -scale 2000 -quality 75 -strip ' . $lock . '/' . $directory . '_tif/jpegs/' . $tiff . '.large.jpg', $output );

						exec( 'montage ' . $lock . '/' . $directory . '_tif/jpegs/' . $tiff . '.large.jpg ' . $scriptpath . '/images/' . $footer . '_2000.gif -tile 1x2 -geometry +0+0 -quality 75 ' . $lock . '/' . $directory . '_tif/jpegs/' . $tiff . '.large.jpg', $output );

						exec( 'convert ' . $lock . '/' . $directory . '_tif/jpegs/' . $tiff . '.large.jpg -gravity south -stroke none -fill white -annotate +50+50 \'http://digital.slub-dresden.de/id' . $ppn . '/' . $i . '\' -quality 75 ' . $lock . '/' . $directory . '_tif/jpegs/' . $tiff . '.large.jpg', $output );

						exec( 'convert ' . $lock . '/' . $directory . '_tif/jpegs/' . $tiff . '.original.jpg -scale 150x150 -strip -quality 75 ' . $lock . '/' . $directory . '_tif/jpegs/' . $tiff . '.thumbnail.jpg', $output );

					}

				}

				exec( 'cd ' . $lock . '/' . $directory . '_tif/jpegs && pdftk *.pdf cat output ' . $ppn . '.pdf', $output );

				exec( 'cd ' . $lock . ' && ln -sf ' . $directory . '_tif ' . $ppn . '_tif', $output );

				exec( 'cd ' . $lock . '/' . $directory . '_tif && rm -f *.tif', $output );

				exec( 'touch ' . $lock . '/ready-for-indexing', $output );

				if( !empty( $output ) ) {

					echo '  '.implode( "\n  ", $output )."\n";

				}

				echo "Done!\n";

			}

		}

	}

}

}

?>