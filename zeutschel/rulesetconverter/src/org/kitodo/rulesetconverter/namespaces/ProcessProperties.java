package org.kitodo.rulesetconverter.namespaces;

import org.kitodo.dataaccess.NodeReference;
import org.kitodo.dataaccess.format.xml.Namespaces;
import org.kitodo.dataaccess.storage.memory.MemoryNodeReference;

public class ProcessProperties {

    public final NodeReference ACCESS;
    public final NodeReference DEFAULTVALUE;
    public final NodeReference NAME;
    public final NodeReference PROPERTY;
    public final NodeReference PROJECT;
    public final NodeReference SHOW_PROCESS_GROUP;
    public final NodeReference SHOW_STEP;
    public final NodeReference TYPE;
    public final NodeReference VALIDATION;
    public final NodeReference VALUE;

    public final String NAMESPACE;

    public ProcessProperties(String namespace) {
	NAMESPACE = namespace;

	ACCESS = new MemoryNodeReference(Namespaces.concat(namespace, "access"));
	DEFAULTVALUE = new MemoryNodeReference(Namespaces.concat(namespace, "defaultvalue"));
	NAME = new MemoryNodeReference(Namespaces.concat(namespace, "name"));
	PROJECT = new MemoryNodeReference(Namespaces.concat(namespace, "project"));
	PROPERTY = new MemoryNodeReference(Namespaces.concat(namespace, "property"));
	SHOW_PROCESS_GROUP = new MemoryNodeReference(Namespaces.concat(namespace, "showProcessGroup"));
	SHOW_STEP = new MemoryNodeReference(Namespaces.concat(namespace, "showStep"));
	TYPE = new MemoryNodeReference(Namespaces.concat(namespace, "type"));
	VALIDATION = new MemoryNodeReference(Namespaces.concat(namespace, "validation"));
	VALUE = new MemoryNodeReference(Namespaces.concat(namespace, "value"));
    }
}
