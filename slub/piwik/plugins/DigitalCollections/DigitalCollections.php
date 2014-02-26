<?php
/**
 * Ordnet aufgerufene Digitalisate in Echtzeit Kollektionen zu; implementiert grafische Schnittstelle.
 *
 * @author Nikolaus Th�mmel
 * @package DigitalCollections
 *
 */

require_once PIWIK_INCLUDE_PATH . '/plugins/DigitalCollections/functions.php';

class Piwik_DigitalCollections extends Piwik_Plugin {


	public static $valuefield = 'visits';

	/**
	 * Return information about this plugin.
	 *
	 * @see Piwik_Plugin
	 *
	 * @return array
	 */
	public function getInformation()
	{
		return array(
			'description' => "Ermittelt die Aufrufe digitaler Kollektionen.",
			'homepage' => 'http://www.slub-dresden.de/',
			'author' => 'Nikolaus Thuemmel, Alexander Bigga',
			'author_homepage' => '',
			'version' => '0.2',
			'translationAvailable' => false,
			'TrackerPlugin' => true,
		);
	}


	/* Erstellt Datenbank f�r Zuordnung Kollektion->idSite
	 * @see Piwik_Plugin::install()
	 */
	public function install() {
		Piwik_Query("CREATE TABLE IF NOT EXISTS ".Piwik_Common::prefixTable("site_collections")." (ID INT(11) AUTO_INCREMENT PRIMARY KEY, cID INT(11), idSite INT(10))");
	}


	/**
	 * Widgets f�r Kollektionen registrieren.
	 * @param Piwik_Event_Notification $notification
	 */
	function addWidget($notification) {
		Piwik_AddWidget('SLUB', 'Kollektionen', 'DigitalCollections', 'collections');
		Piwik_AddWidget('SLUB', 'Kollektionen - Projekte', 'DigitalCollections', 'collections_projects');
	}


	/**
	 * Hooks registrieren.
	 * @see Piwik_Plugin::getListHooksRegistered()
	 */
	public function getListHooksRegistered()
	{
		return array(
			'WidgetsList.add' => 'addWidget',
			'ArchiveProcessing_Day.compute' => 'archiveDay',
			'ArchiveProcessing_Period.compute' => 'archivePeriod',
			'Tracker.Action.record' => 'redirectCollections',
		);
	}


	function archivePeriod( $notification )
	{
		Piwik_cdebug::clog('archivePeriod');

		try {
			$archiveProcessing = $notification->getNotificationObject();
			if(!$archiveProcessing->shouldProcessReportsForPlugin($this->getPluginName())) {
				$this->clog("archivePeriod-Error: return");
//				return;
			}

	                $dataTableToSum = array(
                                'DigitalCollections_value',
        	        );
	                $archiveProcessing->archiveDataTable($dataTableToSum);
		} catch(Exception $e) {
			Piwik_cdebug::clog("archivePeriod-Error: ".$e->getMessage());
		}
	}


	public function archiveDay( $notification )
	{
		Piwik_cdebug::clog('archiveDay');
		try {
			$archiveProcessing = $notification->getNotificationObject();
			if(!$archiveProcessing->shouldProcessReportsForPlugin($this->getPluginName())) {
				$this->clog("archiveDay-Error: return");
				return;
			}

			$recordName = 'DigitalCollections_value';
			$table = $this->getCollectionData($archiveProcessing);
			$columnToSortByBeforeTruncation = self::$valuefield;
			$archiveProcessing->insertBlobRecord($recordName, $archiveProcessing->getDataTableSerialized($table), null, $columnToSortByBeforeTruncation);
		} catch(Exception $e) {
			Piwik_cdebug::clog("archiveDay-Error: ".$e->getMessage());
		}
	}


	/**
	 * Ordnet f�r den gegebenen Archivzeitraum allen Digitalisat-URLs Kollektionen zu,
	 * und archiviert diese.
	 * @param Piwik_ArchiveProcessing_Day $archiveProcessing
	 * @return Piwik_DataTable
	 */
	private function getCollectionData($archiveProcessing) {

		Piwik_cdebug::clog('getCollectionData');

		$collections = array();
		$query = $archiveProcessing->queryActionsByDimension('idaction_url');
		while($row = $query->fetch()) {
			$url = Piwik_FetchOne("SELECT name FROM ".Piwik_Common::prefixTable("log_action")." WHERE idaction = ?", $row["label"]);
			$idcollections = $this->getCollectionsForURL($url);
			if(!is_array($idcollections) || count($idcollections)<1) continue;
			foreach($idcollections as $c) {
				if(!array_key_exists($c, $collections)) {
					$collections[$c] = array(self::$valuefield=>1);
				} else {
					$collections[$c][self::$valuefield]++;
				}
			}
		}

		return $collections;
	}


	/**
	 * L�dt Kollektions-IDs aus der TYPO3-Datenbank f�r eine bestimmte URL (und damit ID).
	 * @param String $url
	 * @return array
	 */
	private function getCollectionsForURL($url) {

		// this function is called on every piwik call
		// we are only interested in calls for dlf-extension
		if (strpos($url, "dlf") === FALSE)
                        return NULL;

		// try to find the id of the digitalisat
		$urlparsed = parse_url(urldecode($url));
		// default
		$id = 0;

		// 1st try:
		// urls like: http://digital.slub-dresden.de/werkansicht/cache.off?id=5363&tx_dlf[id]=15997&tx_dlf[page]=10
		if (!empty($urlparsed['query'])) {
			$qfields = preg_split('/[;&]/', $urlparsed['query']);
			$params = array();
    			foreach ($qfields as $param) {
			        $item = explode('=', $param);
			 	if (sizeof($item)==2)
				       $params[$item[0]] = $item[1];
			}
			if (isset($params['tx_dlf[id]']))
				$id = $params['tx_dlf[id]'];
		}

		// 2nd try:
		// urls like: http://digital.slub-dresden.de/werkansicht/dlf/2967/57/cache.off
		if ($id <=0) {
			$this->clog("getCollectionsForURL: " . $urlparsed['path']);
			$qsplit = explode("/",$urlparsed['path']);
			$idpos = array_search('dlf', $qsplit) + 1;
			$id = intval($qsplit[$idpos]);
		}
		$this->clog("getCollectionsForURL(".$url."). id=/". $id."/");

		// none was successful --> abort
		if ($id <=0)
			return NULL;

		$mysqli = mysqli_connect("MYSQLSERVER","USER","PASSWORD", "DATABASE");
		mysqli_set_charset($mysqli, 'utf8');

		// ID DER KOLLEKTIONEN ZUORDNEN
		$result = mysqli_query($mysqli, "SELECT uid_foreign FROM tx_dlf_relations WHERE ident='docs_colls' AND uid_local=".$id);
		Piwik_cdebug::clog("getCollectionsForURL: SELECT uid_foreign FROM tx_dlf_relations WHERE ident='docs_colls' AND uid_local=".$id);
		$collections = array();
		if ($result) {
			while($tmpc = mysqli_fetch_row($result)) {
				$collections[] = $tmpc[0];
			}
		} else
			Piwik_cdebug::clog("getCollectionsForURL(".$url.") --> no result!");

		mysqli_close($mysqli);

		Piwik_cdebug::clog("getCollectionsForURL(".$url.")".print_r($collections, 1));

		return $collections;
	}


	/**
	 * Log-Erstellung. debugging.
	 * @param String $str
	 */
	private function clog($str) {
		return;
		$file = fopen("/var/log/piwik-collection_log.txt", "a");
		fputs($file, strftime('%c') . ': ' . $str."\n");
		fclose($file);
	}



	/**
	 * Kollektionen werden an Kollektions-idSites weitergeleitet und f�llen ihre eigene Statistik.
	 * @param unknown_type $notification
	 */
	public function redirectCollections($notification) {
		try {
			if($tmp = Piwik_Common::getRequestVar("colacnt","false","string")=="true") return;
			$openedurl = Piwik_Common::getRequestVar("url");
			$collections = $this->getCollectionsForURL($openedurl);
			if($collections==null || count($collections)<1) return;
			require_once PIWIK_INCLUDE_PATH .'/core/Loader.php';

			$murl = $this->curPageURL();
			$ua = $_SERVER["HTTP_USER_AGENT"];
			$acceptLanguage = $_SERVER["HTTP_ACCEPT_LANGUAGE"];

			foreach($collections as $c) {
				$idSite = Piwik_FetchOne("SELECT idSite FROM ".Piwik_Common::prefixTable("site_collections")." WHERE cID = ?", $c);
				$name = "(Kollektion) ".getCollectionNames($c);

				//Kollektion hat noch keine idSite! -> wird erstellt
				if(!is_numeric($idSite)) {
					Piwik_Query("INSERT INTO ".Piwik_Common::prefixTable("site").
							" (idsite, name, main_url, ts_created, timezone, currency, excluded_ips, excluded_parameters, `group`) ".
							"VALUES('', ?, ?, NOW(), 'Europe/Berlin', 'EUR', '', '', 'Digitale Kollektionen')",
					 		array($name, "slub-dresden.de"));
					$idSite = Piwik_FetchOne("SELECT LAST_INSERT_ID() FROM ".Piwik_Common::prefixTable("site"));
					Piwik_Query("INSERT INTO ".Piwik_Common::prefixTable("site_collections")." (ID, cID, idSite) VALUES ('', ?, ?)",array($c,$idSite));
				}

				//idSite zur Kollektion wurde gel�scht! -> neu erstellen
				if(Piwik_FetchOne("SELECT COUNT(idsite) FROM ".Piwik_Common::prefixTable("site")." WHERE idsite = ?",$idSite)==0) {
					Piwik_Query("INSERT INTO ".Piwik_Common::prefixTable("site").
							" (idsite, name, main_url, ts_created, timezone, currency, excluded_ips, excluded_parameters, `group`) ".
							"VALUES(?, ?, ?, NOW(), 'Europe/Berlin', 'EUR', '', '', 'Digitale Kollektionen')",
					 		array($idSite, $name, "slub-dresden.de"));
				}

				$url = preg_replace("/idsite=[0-9]+/", "idsite=".$idSite, $murl);
				// Erneute Kollektionsweiterleitung verhindern
				$url .= "&colacnt=true";
				// Disable provider plugin
				$url .= "&dp=1";
				Piwik_Http::sendHttpRequest($url, 5, $ua, null, 0, $acceptLanguage);
			}
		} catch (Exception $e) {
			$this->clog("redirectCollections-Error: ".$e->getMessage());
		}
	}


	/**
	 * Quelle: http://www.webcheatsheet.com/PHP/get_current_page_url.php
	 * @return string
	 */
	private function curPageURL() {
	 	$pageURL = 'http';
	 	if (@$_SERVER["HTTPS"] == "on") {$pageURL .= "s";}
		$pageURL .= "://";
		if ($_SERVER["SERVER_PORT"] != "80") {
			$pageURL .= $_SERVER["SERVER_NAME"].":".$_SERVER["SERVER_PORT"].$_SERVER["REQUEST_URI"];
		} else {
			$pageURL .= $_SERVER["SERVER_NAME"].$_SERVER["REQUEST_URI"];
		}
		return $pageURL;
	}


}


/**
 * L�st Kollektions-IDs in Namen auf.
 * @param String $label
 * @return String
 */
function getCollectionNames($label) {
	Piwik_cdebug::clog('getCollectionNames: '.$label);
	$mysqlh = mysql_connect("MYSQLSERVER","USER","PASSWORD");
	mysql_set_charset('utf8', $mysqlh);
	mysql_select_db("DATABASE",$mysqlh);
	$result = mysql_query("SELECT label FROM tx_dlf_collections WHERE uid=".$label,$mysqlh);
	$row = mysql_fetch_row($result);
	mysql_close($mysqlh);
	return $row[0];
}

?>
