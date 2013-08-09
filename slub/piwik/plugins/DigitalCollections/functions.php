<?PHP

class Piwik_cdebug {
       /**
         * debugging.
         * @param String $str
         */
        public function clog($str) {
		// deactivated by default
		return;

                $file = fopen("/var/log/piwik-collection_log.txt", "a");
                fputs($file, strftime('%c') . ': ' . $str."\n");
                fclose($file);
        }

}
?>
