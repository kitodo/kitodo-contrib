package org.kitodo.rulesetconverter.namespaces;

import org.kitodo.dataaccess.NodeReference;
import org.kitodo.dataaccess.format.xml.Namespaces;
import org.kitodo.dataaccess.storage.memory.MemoryNodeReference;

public class DigitalCollections {

    public final NodeReference DEFAULT;
    public final NodeReference DIGITAL_COLLECTION;
    public final NodeReference NAME;
    public final NodeReference PROJECT;

    public final String NAMESPACE;

    public DigitalCollections(String namespace) {
        NAMESPACE = namespace;
        DEFAULT = new MemoryNodeReference(Namespaces.concat(namespace, "default"));
        DIGITAL_COLLECTION = new MemoryNodeReference(Namespaces.concat(namespace, "DigitalCollection"));
        NAME = new MemoryNodeReference(Namespaces.concat(namespace, "name"));
        PROJECT = new MemoryNodeReference(Namespaces.concat(namespace, "project"));
    }
}
