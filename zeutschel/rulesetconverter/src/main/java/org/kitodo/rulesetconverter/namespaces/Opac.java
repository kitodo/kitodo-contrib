/*
 * This file is licensed under GNU General Public License version 3 or later.
 */
package org.kitodo.rulesetconverter.namespaces;

import org.kitodo.dataaccess.NodeReference;
import org.kitodo.dataaccess.format.xml.Namespaces;
import org.kitodo.dataaccess.storage.memory.MemoryNodeReference;

public class Opac {

    public final NodeReference DOCTYPES;
    public final NodeReference IS_NEWSPAPER;
    public final NodeReference LABEL;
    public final NodeReference LANGUAGE;
    public final NodeReference RULESET_TYPE;
    public final NodeReference TITLE;
    public final NodeReference TYPE;

    public final String NAMESPACE;

    public Opac(String namespace) {
        NAMESPACE = namespace;

        DOCTYPES = new MemoryNodeReference(Namespaces.concat(namespace, "doctypes"));
        IS_NEWSPAPER = new MemoryNodeReference(Namespaces.concat(namespace, "isNewspaper"));
        LABEL = new MemoryNodeReference(Namespaces.concat(namespace, "label"));
        LANGUAGE = new MemoryNodeReference(Namespaces.concat(namespace, "language"));
        RULESET_TYPE = new MemoryNodeReference(Namespaces.concat(namespace, "rulesetType"));
        TITLE = new MemoryNodeReference(Namespaces.concat(namespace, "title"));
        TYPE = new MemoryNodeReference(Namespaces.concat(namespace, "type"));
    }

}
