#!/usr/bin/env bash
#
# (c) 2018 Technische Universität Berlin
#
# This software is licensed under GNU General Public License version 3 or later.
#
# For the full copyright and license information,
# please see https://www.gnu.org/licenses/gpl-3.0.html or read
# the LICENSE.txt file that was distributed with this source code.
#

#########################
#
# Creates a DOI by DataCite, reserves it, and writes it to the METS/MODS file.
# Optionally also registers the DOI to a landing page. (See $REGISTER_DOI)
#
# In order to use this script, you need to have an account by DataCite.
#
# DataCite API documentation: https://support.datacite.org/docs/mds-2
#
# Parameter $1: process id    (required)
# Parameter $2: process path  (required)
# Parameter $3: catalog id    (optional)
#
#########################

set -e

# Including the log function
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )";
source ${DIR}/logging.sh;

SCRIPT_NAME="doi_creation.sh";

PROCESS_ID=$1
PROCESS_PATH=$2
CATALOG_ID=$3


###############################
#
# Configuration parameter
#
###############################

# User name bei DataCite
DOI_USER="USER.NAME"

# Password bei DataCite
DOI_PASSWORD="SECRET" # test password

# Prefix to be used in the doi. As a default, the prefix ist set to the common datacite test prefix.
# This must be changed for production.
DOI_PREFIX="10.5072" # common test prefix - don't use this in production

# Optional separator for the doi. This may be used if prefix with process id alone does not create a unique doi.
DOI_NAMESPACE_SEPARATOR=

# Datacite url. As a default, the test url is used. This must be changed for production.
DATACITE_URL="https://mds.test.datacite.org"  # test site - don't use this in production

# Set this value to false if the DOI is registered at a later point.
REGISTER_DOI="true"

# If the doi is registered directly after reservation, this may fail since doi itself is dependent upon handle
SLEEP_BEFORE_REGISTER=15

# Landing page pattern to be used if the DOI registration takes place here.
DOI_LANDING_PAGE_PATTERN="https://example.org/<CatalogID>"

# Path to the XSLT files
XSLT_PATH="${DIR}/xslt"

# Name of the XSLT file for creation of the datacite metadata XML.
XSLT_METS2DOI="${XSLT_PATH}/mets2dataCiteMetadata.xsl"

# Name of the XSLT file writing the doi in the METS/MODS file
XSLT_WRITE_DOI_IN_METS="${XSLT_PATH}/doi2mets.xsl"

# Path to the METS/MODS file
METSMODS_FILE="${PROCESS_PATH}/meta.xml"

# Path to the
DOI_METADATA_PATH="${PROCESS_PATH}/doi_metadata"
DOI_METADATA_FILE="${DOI_METADATA_PATH}/doi_metadata.xml"


###############################
#
# Checks
#
###############################

## Check that required software is installed
type -P xsltproc &>/dev/null || {
    error "$SCRIPT_NAME - xsltproc is required but seems not to be installed. Aborting." >&2;
    exit 1;
}

# Check required parameter
if [ -z "${PROCESS_ID}" -o -z "${PROCESS_PATH}" ]; then
    USAGE="Usage: ${SCRIPT_NAME} {processid} {processpath} {processtitle}";
    error "${SCRIPT_NAME}: - Script called with unsufficient parameters. ${USAGE}";
    echo ${USAGE};
    exit 1;
fi

# Check existens of METS/MODS and XSLT files
if [ ! -e "${METSMODS_FILE}" ]; then
    error "${SCRIPT_NAME}: METS/MODS file ${METSMODS_FILE} not found, exiting.";
    exit 1;
fi

if [ ! -e "${XSLT_METS2DOI}" ]; then
    error "${SCRIPT_NAME}: XSLT file ${XSLT_METS2DOI} not found, exiting.";
    exit 1;
fi

if [ ! -e "${XSLT_WRITE_DOI_IN_METS}" ]; then
    error "${SCRIPT_NAME}: XSLT file ${XSLT_WRITE_DOI_IN_METS} not found, exiting.";
    exit 1;
fi

if [ ! -e "${DOI_METADATA_PATH}" ]; then
    mkdir ${DOI_METADATA_PATH}
fi


###############################
#
# Body
#
###############################

# Mint doi
DOI="${DOI_PREFIX}/${DOI_NAMESPACE_SEPARATOR}${PROCESS_ID}"

# Check if the METS/MODS file already contains a DOI. If it contains a different doi than the one just created, exit.
DOI_IN_METS=$(sed "s/.*<goobi:metadata name=\"DOI\">\([^<]\+\)<\/goobi:metadata>.*/\1/;tx;d;:x" ${METSMODS_FILE});

if [ -n "${DOI_IN_METS}" ] && [[ "${DOI}" != "${DOI_IN_METS}" ]]; then
    error "DOI ${DOI_IN_METS} already present in METS/MODS file. Since it is different from the just created DOI ${DOI} there is something wrong. Exiting.";
    exit 1;
fi

if [[ "${DOI}" == "${DOI_IN_METS}" ]]; then
    info "DOI ${DOI} already present in METS/MODS file. Updating metadata.";
    update=true;
fi

# Create DataCite metadata file
xsltproc -o ${DOI_METADATA_FILE} --stringparam doi ${DOI} --stringparam year $(date +%Y) ${XSLT_METS2DOI} ${METSMODS_FILE}
XSLT_RETURN=$?
if [ ${XSLT_RETURN} -ne 0 ]; then
    error "Error creating doi metadata file for ${METSMODS_FILE}, xslt stylesheet: ${XSLT_METS2DOI}, doi: ${DOI}, return code from xsltproc: ${XSLT_RETURN}";
    exit 1;
fi

# Send metadata file to DataCite (this reserves the doi; if the doi already exists, it updates the metadata)
STATUS=$(curl --write-out %{http_code} --silent --output /dev/null -H "Content-Type:application/xml;charset=UTF-8" -X POST -i --user ${DOI_USER}:${DOI_PASSWORD} -d @${DOI_METADATA_FILE} ${DATACITE_URL}/metadata)

if [[ ${STATUS} == 20* ]]; then
    info "DOI ${DOI} successfully reserved, status code: ${STATUS}";
else
    error "Reservation of DOI ${DOI} by DataCite failed, status code: ${STATUS}";
    exit 1;
fi

# Write the DOI to the METS/MODS file - but only when not updating the doi
if [[ ${update} != "true" ]]; then
    mv ${METSMODS_FILE} ${METSMODS_FILE}.tmp
    xsltproc --stringparam doi ${DOI} ${XSLT_WRITE_DOI_IN_METS} ${METSMODS_FILE}.tmp > ${METSMODS_FILE}
    XSLT_RETURN=$?

    if [ ${XSLT_RETURN} -ne 0 ]; then
        error "Error writing doi to ${METSMODS_FILE}, xslt stylesheet: ${XSLT_WRITE_DOI_IN_METS}, doi: ${DOI}, return code from xsltproc: ${XSLT_RETURN}";
        mv ${METSMODS_FILE}.tmp ${METSMODS_FILE}
        exit 1;
    fi
    info "DOI written to METS/MODS file":
    rm ${METSMODS_FILE}.tmp
fi


# Register DOI

if [[ ${REGISTER_DOI} == "true" ]]; then
    DOI_LANDING_PAGE=$(echo "${DOI_LANDING_PAGE_PATTERN}" | sed "s/<CatalogID>/${CATALOG_ID}/");

    # DataCite Documentation:
    # "If you create a DOI and then immediately try to update its URL, you might get the error message HANDLE NOT EXISTS
    # (404 or 204). This is because it takes some time for the system to register a handle for a DOI."
    # Thus: sleep for a while
    sleep ${SLEEP_BEFORE_REGISTER};

    STATUS_REGISTER=$(curl --write-out %{http_code} --silent --output /tmp/kitodo/output.txt -H "Content-Type:text/plain;charset=UTF-8" -X PUT --user ${DOI_USER}:${DOI_PASSWORD} -d doi=${DOI}$'\n'url=${DOI_LANDING_PAGE} ${DATACITE_URL}/doi/${DOI});
    if [[ ${STATUS_REGISTER} == 20* ]]; then
        info "DOI ${DOI} successfully registered to landing page ${DOI_LANDING_PAGE}, status code: ${STATUS_REGISTER}";
    else
        error "Regitration of DOI ${DOI} to landing page ${DOI_LANDING_PAGE} failed, status code: ${STATUS_REGISTER}";
        exit 1;
    fi
else
    info "DOI ${DOI} was reserved but not registered to a landing page, since the configuration parameter REGISTER_DOI is set to ${REGISTER_DOI}.";
fi
