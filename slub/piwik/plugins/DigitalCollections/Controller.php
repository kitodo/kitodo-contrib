<?php 

/**
 *
 * @author Nikolaus Thümmel
 * @package DigitalCollections
 *
 */

require_once PIWIK_INCLUDE_PATH . '/plugins/DigitalCollections/functions.php';

class Piwik_DigitalCollections_Controller extends Piwik_Controller {
	
	public function collections($fetch = false) {
		
		$view = Piwik_ViewDataTable::factory();
		$view->init( $this->pluginName,  __FUNCTION__, "DigitalCollections.getCollectionTable" );
		
		$this->configView($view);
		
		return $this->renderView($view,$fetch);
	}
	
	public function collections_projects($fetch = false) {
		
		$view = Piwik_ViewDataTable::factory();
		$view->init( $this->pluginName,  __FUNCTION__, "DigitalCollections.getCollectionTableProjects" );
		
		$this->configView($view);
		
		return $this->renderView($view,$fetch);
	}
	
	private function configView($view) {
		$view->setColumnTranslation(Piwik_DigitalCollections::$valuefield, "Aufrufe");
		$view->setColumnTranslation('label', "Kollektion");
		$view->setSortedColumn(Piwik_DigitalCollections::$valuefield,'desc');
		$view->setColumnsToDisplay( array('label', Piwik_DigitalCollections::$valuefield) );
		//$view->disableSort();
		$view->setGraphLimit(8);
		$view->setLimit(10);
		$view->disableShowAllColumns();
		//$view->disableExcludeLowPopulation();
		$this->setGeneralVariablesView($view);
	}

}

?>
