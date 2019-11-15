/*
 * This file is licensed under GNU General Public License version 3 or later.
 */
package org.kitodo.rulesetconverter.namespaces;

import org.apache.jena.rdf.model.*;
import org.kitodo.dataaccess.NodeReference;

public enum DisplayRules implements NodeReference {
    BIND("http://meta.goobi.org/displayRules#bind"),
    CONTEXT("http://meta.goobi.org/displayRules#context"),
    INPUT("http://meta.goobi.org/displayRules#input"),
    ITEM("http://meta.goobi.org/displayRules#item"),
    LABEL("http://meta.goobi.org/displayRules#label"),
    PROJECT_NAME("http://meta.goobi.org/displayRules#projectName"),
    REF("http://meta.goobi.org/displayRules#ref"),
    RULESET("http://meta.goobi.org/displayRules#ruleSet"),
    SELECT1("http://meta.goobi.org/displayRules#select1"),
    SELECTED("http://meta.goobi.org/displayRules#selected"),
    VALUE("http://meta.goobi.org/displayRules#value");

    public static final String NAMESPACE = "http://meta.goobi.org/displayRules#";

    private String identifier;

    private DisplayRules(String identifier) {
	this.identifier = identifier;
    }

    @Override
    public String getIdentifier() {
	return identifier;
    }

    @Override
    public RDFNode toRDFNode(Model model, Boolean unused) {
	return model.createResource(identifier);
    }

    @Override
    public String toString() {
	return '↗' + identifier;
    }
}
