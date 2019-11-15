/*
 * This file is licensed under GNU General Public License version 3 or later.
 */
package org.kitodo.rulesetconverter.namespaces;

import org.kitodo.dataaccess.NodeReference;
import org.kitodo.dataaccess.format.xml.Namespaces;
import org.kitodo.dataaccess.storage.memory.MemoryNodeReference;

public class Projects {

    public final NodeReference CREATE_NEW_PROCESS;
    public final NodeReference DOCSTRUCT;
    public final NodeReference FROM;
    public final NodeReference ISDOCTYPE;
    public final NodeReference ISNOTDOCTYPE;
    public final NodeReference ITEM;
    public final NodeReference ITEMLIST;
    public final NodeReference LABEL;
    public final NodeReference METADATA;
    public final NodeReference NAME;
    public final NodeReference PROJECT;
    public final NodeReference REQUIRED;
    public final NodeReference SELECT;
    public final NodeReference UGHBINDING;

    public final String NAMESPACE;

    public Projects(String namespace) {
	NAMESPACE = namespace;
	CREATE_NEW_PROCESS = new MemoryNodeReference(Namespaces.concat(namespace, "createNewProcess"));
	DOCSTRUCT = new MemoryNodeReference(Namespaces.concat(namespace, "docstruct"));
	FROM = new MemoryNodeReference(Namespaces.concat(namespace, "from"));
	ISDOCTYPE = new MemoryNodeReference(Namespaces.concat(namespace, "isdoctype"));
	ISNOTDOCTYPE = new MemoryNodeReference(Namespaces.concat(namespace, "isnotdoctype"));
	ITEM = new MemoryNodeReference(Namespaces.concat(namespace, "item"));
	ITEMLIST = new MemoryNodeReference(Namespaces.concat(namespace, "itemlist"));
	LABEL = new MemoryNodeReference(Namespaces.concat(namespace, "label"));
	METADATA = new MemoryNodeReference(Namespaces.concat(namespace, "metadata"));
	NAME = new MemoryNodeReference(Namespaces.concat(namespace, "name"));
	PROJECT = new MemoryNodeReference(Namespaces.concat(namespace, "project"));
	REQUIRED = new MemoryNodeReference(Namespaces.concat(namespace, "required"));
	SELECT = new MemoryNodeReference(Namespaces.concat(namespace, "select"));
	UGHBINDING = new MemoryNodeReference(Namespaces.concat(namespace, "ughbinding"));
    }
}
