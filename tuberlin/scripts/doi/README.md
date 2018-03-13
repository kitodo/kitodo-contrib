# Script creating DOI for Kitodo.Production 2.x

This directory suppplies BASH scripts and XSLT files for creating, reserving and registering a DOI in Kitodo.Production 2.x.
  
The script is intended as a script step in Kitodo.Production, after metadata editing and before export.

Main script: `doi_creation.sh`

## Prerequisites

In order to register DOIs, you need to have an account at a DOI registration agency. As a default, this implementation presupposes that you have an account by DataCite, but there are several other [DOI registration agencies](https://www.doi.org/registration_agencies.html).

In Germany, you may get a [DataCite account by TIB Hannover](https://www.tib.eu/en/publishing-archiving/doi-service/information-for-interested-parties/).

### Software requirements

You must have `xsltproc` installed on your server to be able to run the script.

## Configuration

The script and the XSL transformations need to be configured and adapted in a number of ways. 

### doi_creation.sh

The main script `doi_creation.sh` has several configuration parameters, the most important are:

* DOI_USER (User name for DataCite)

* DOI_PASSWORD (Password for DataCite)

* DOI_PREFIX (DOI prefix for the application, to be obtained by DataCite)

* DOI_NAMESPACE_SEPARATOR (Optional separator for the DOI)

* DATACITE_URL (Datacite url; as a default, the test url is used)

* REGISTER_DOI (Set this to false if the DOI should be registered (= activated) at a later point)

* DOI_LANDING_PAGE_PATTERN (Landing page pattern to be used if the DOI registration takes place here)

For more information, see the comments in the script.

#### Minting the DOI

A DOI name always contains a prefix of the institute followed by a '/' and a string. The only requirements on the string is, that it together with the prefix is unique.
In this implementation, the internal process id is used for the unique string, as follows:
```
DOI="${DOI_PREFIX}/${DOI_NAMESPACE_SEPARATOR}${PROCESS_ID}"
```
If for some reason, the process id alone does not guarantee uniqueness, you may set the namespace separator.
Of course, you can also change the implementation to use something else for the unique string, such as a catalog id.

### logging.sh

Here, the path to the log file and (if you wish) an admin email address should be set. 

### mets2dataCiteMetadata.xsl

Reserving a DOI, you send metadata to DataCite using [a certain schema](https://schema.datacite.org/).
This file maps the metadata in the internal Mets/Mods file of Kitodo to a datacite metadata file.

Of course, this mapping depends on the metadata fields used by the current institute and needs to be adapted.
The file is provided with extensive comments to make this adaption easier.

### ruleset.xml

In order to work with DOIs, the ruleset.xml has to be extended with a doi field.

Examples:
```
  <MetadataType>
    <Name>_doi</Name>
    <language name="de">DOI Intern</language>
    <language name="en">DOI Internal</language>
  </MetadataType>
```

```
  <Metadata>
    <InternalName>_doi</InternalName>
    <WriteXPath>./mods:mods/#mods:identifier[@type='doi']</WriteXPath>
  </Metadata>
```
Additionally, every DocStructType that is a topStruct should be extended with the DOI field. 

If a different InternalName is used, this also has to be changed in `doi2mets.xsl`, where the DOI ist written to the internal Mets/Mods file. 
