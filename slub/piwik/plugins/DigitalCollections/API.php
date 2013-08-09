<?php

/**
 * API für Datenanzeige und Archivverwaltung der digitalen Kollektionen der SLUB.
 * @author Nikolaus Thuemmel
 * @package DigitalCollections
 *
 */

require_once PIWIK_INCLUDE_PATH . '/plugins/DigitalCollections/functions.php';

class Piwik_DigitalCollections_API {

	static private $instance = null;

	static public function getInstance() {
		if (self::$instance == null) {
			self::$instance = new self;
		}
		return self::$instance;
	}

	/**
	 * Anzahl der Kollektionsaufrufe abfragen.
	 * @return Piwik_DataTable
	 */
	public function getCollectionTable( $idSite, $period, $date, $segment = false) {
		$dataTable = self::getCollectionTableFromArchive($idSite, $period, $date, $segment);
		self::filterCollectionTableContent($dataTable, "Projekt:", false);
		return $dataTable;
	}

	public function getCollectionTableProjects( $idSite, $period, $date, $segment = false) {
		$dataTable = self::getCollectionTableFromArchive($idSite, $period, $date, $segment);
		self::filterCollectionTableContent($dataTable, "Projekt:", true);
		return $dataTable;
	}


	/**
	 * Gibt eine sortierte DataTable mit Kollektionen aus den Archiven zur�ck.
	 * @param int $idSite
	 * @param unknown_type $period
	 * @param unknown_type $date
	 * @param boolean $segment
	 * @return Piwik_DataTable
	 */
	protected function getCollectionTableFromArchive($idSite, $period, $date, $segment) {
	//	defined('PIWIK_INCLUDE_PATH') or die('Restricted access');
		Piwik_cdebug::clog('getCollectionTableFromArchive: ' . $idSite . ' period: '.$period);
		Piwik::checkUserHasViewAccess( $idSite );

		$archive = Piwik_Archive::build($idSite, $period, $date, $segment );
		$dataTable = $archive->getDataTable("DigitalCollections_value");

		Piwik_cdebug::clog('getCollectionTableFromArchive: dataTable: ' . count($dataTable));
		Piwik_cdebug::clog('getCollectionTableFromArchive: dataTable: ' . print_r($dataTable, 1));

		$dataTable->filter('Sort', array(Piwik_DigitalCollections::$valuefield, 'desc'));

		$dataTable->filter('ColumnCallbackAddMetadata', array( 'label', 'url', 'getCollectionUrlFromID', array($date,$period)));
		$dataTable->filter('ColumnCallbackReplace', array('label', 'getCollectionNames'));
		$dataTable->filter('ReplaceColumnNames');

		//INDEX_NB_VISITS-Spalte zur richtigen Graphen-Anzeige hinzuf�gen --> ACHTUNG! Muss im Controller ausgeblendet werden!
		$rows = $dataTable->getRows();
		Piwik_cdebug::clog('getCollectionTableFromArchive: rows: '. count($rows));
		foreach($rows as $i => $row) {
			Piwik_cdebug::clog('getCollectionTableFromArchive: '.$i);
			$row->addColumn(Piwik_Archive::INDEX_NB_VISITS, $row->getColumn("visits"));
		}

		return $dataTable;
	}


	/**
	 * Filtert Kollektionsdaten nach Strings. -> z.B. Unterscheidung Standard <-> Projekt
	 * @param Piwik_DataTable $dataTable
	 * @param String $filter
	 * @param boolean $bool
	 */
	private static function filterCollectionTableContent($dataTable, $filter, $bool) {
		$rows = $dataTable->getRows();
		Piwik_cdebug::clog('filterCollectionTableContent: rows: '. count($rows));
		foreach($rows as $i => $row) {
			$label = $row->getColumn('label');
			if( (strpos($label, $filter)!==false) XOR ($bool) ) $dataTable->deleteRow($i);
		}
	}

}

function getCollectionUrlFromID($id,$date,$period) {
	$pidSite = Piwik_FetchOne("SELECT idSite FROM ".Piwik_Common::prefixTable("site_collections")." WHERE cID = ?", $id);

	Piwik_cdebug::clog('getCollectionUrlFromID: ' . 'http://piwik.slub-dresde.de/index.php?module=CoreHome&action=index&date='.$date.'&period='.$period.'&idSite='.$pidSite);

	if(is_numeric($pidSite)) {
		return "http://piwik.slub-dresden.de/index.php?module=CoreHome&action=index&date=".$date."&period=".$period."&idSite=".$pidSite;
	}
}


?>
