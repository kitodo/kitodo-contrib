/*
 * This file is licensed under GNU General Public License version 3 or later.
 */
package org.kitodo.rulesetconverter.namespaces;

import org.kitodo.dataaccess.NodeReference;
import org.kitodo.dataaccess.format.xml.Namespaces;
import org.kitodo.dataaccess.storage.memory.MemoryNodeReference;

public class Preferences {

    public final NodeReference ALLOWEDCHILDTYPE;
    public final NodeReference DEFAULT_DISPLAY;
    public final NodeReference DOC_STRCT_TYPE;
    public final NodeReference GROUP;
    public final NodeReference LANGUAGE;
    public final NodeReference METADATA;
    public final NodeReference METADATA_TYPE;
    public final NodeReference LOWERCASE_NAME;
    public final NodeReference NUM;
    public final NodeReference TITLECASE_NAME;
    public final NodeReference TYPE;

    public final String NAMESPACE;

    public Preferences(String namespace) {
	NAMESPACE = namespace;
	ALLOWEDCHILDTYPE = new MemoryNodeReference(Namespaces.concat(namespace, "allowedchildtype"));
	DEFAULT_DISPLAY = new MemoryNodeReference(Namespaces.concat(namespace, "DefaultDisplay"));
	DOC_STRCT_TYPE = new MemoryNodeReference(Namespaces.concat(namespace, "DocStrctType"));
	GROUP = new MemoryNodeReference(Namespaces.concat(namespace, "Group"));
	LANGUAGE = new MemoryNodeReference(Namespaces.concat(namespace, "language"));
	METADATA = new MemoryNodeReference(Namespaces.concat(namespace, "metadata"));
	METADATA_TYPE = new MemoryNodeReference(Namespaces.concat(namespace, "MetadataType"));
	LOWERCASE_NAME = new MemoryNodeReference(Namespaces.concat(namespace, "name"));
	TITLECASE_NAME = new MemoryNodeReference(Namespaces.concat(namespace, "Name"));
	NUM = new MemoryNodeReference(Namespaces.concat(namespace, "num"));
	TYPE = new MemoryNodeReference(Namespaces.concat(namespace, "type"));
    }
}
