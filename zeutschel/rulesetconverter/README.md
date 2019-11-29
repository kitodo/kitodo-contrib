Ruleset converter
=================

This is an application to migrate rulesets from Kitodo.Production 2.x format to the new format of Kitodo.Production 3.x.

Usage
-----

example call

```
java -jar rulesetconverter-1.0-SNAPSHOT-jar-with-dependencies.jar \
 -dc "/path/to/goobi_digitalCollections.xml" \
 -md "/path/to/goobi_metadataDisplayRules.xml" \
 -oc "/path/to/goobi_opac.xml" \
 -p  "/path/to/goobi_projects.xml" \
 -pp "/path/to/goobi_processProperties.xml" \
 -r  "/path/to/rulsetFile" \
 -od "/path/to/existingOutputDirectory"
```
