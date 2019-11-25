/*
 * This file is licensed under GNU General Public License version 3 or later.
 */
package org.kitodo.rulesetconverter.namespaces;

import org.apache.jena.rdf.model.Model;
import org.apache.jena.rdf.model.RDFNode;
import org.kitodo.dataaccess.NodeReference;

public enum Ruleset implements NodeReference {
    ACQUISITION_STAGE("http://names.kitodo.org/ruleset/v2#acquisitionStage"),
    ALWAYS_SHOWING("http://names.kitodo.org/ruleset/v2#alwaysShowing"),
    CODOMAIN("http://names.kitodo.org/ruleset/v2#codomain"),
    CORRELATION("http://names.kitodo.org/ruleset/v2#correlation"),
    DATES("http://names.kitodo.org/ruleset/v2#dates"),
    DECLARATION("http://names.kitodo.org/ruleset/v2#declaration"),
    DIVISION("http://names.kitodo.org/ruleset/v2#division"),
    DOMAIN("http://names.kitodo.org/ruleset/v2#domain"),
    EDITABLE("http://names.kitodo.org/ruleset/v2#editable"),
    EDITING("http://names.kitodo.org/ruleset/v2#editing"),
    EXCLUDED("http://names.kitodo.org/ruleset/v2#excluded"),
    KEY("http://names.kitodo.org/ruleset/v2#key"),
    ID("http://names.kitodo.org/ruleset/v2#id"),
    LABEL("http://names.kitodo.org/ruleset/v2#label"),
    LANG("http://names.kitodo.org/ruleset/v2#lang"),
    MIN_OCCURS("http://names.kitodo.org/ruleset/v2#minOccurs"),
    MAX_OCCURS("http://names.kitodo.org/ruleset/v2#maxOccurs"),
    MULTILINE("http://names.kitodo.org/ruleset/v2#multiline"),
    NAME("http://names.kitodo.org/ruleset/v2#name"),
    OPTION("http://names.kitodo.org/ruleset/v2#option"),
    PATTERN("http://names.kitodo.org/ruleset/v2#pattern"),
    PERMIT("http://names.kitodo.org/ruleset/v2#permit"),
    PRESET("http://names.kitodo.org/ruleset/v2#preset"),
    RESTRICTION("http://names.kitodo.org/ruleset/v2#restriction"),
    RULESET("http://names.kitodo.org/ruleset/v2#ruleset"),
    SCHEME("http://names.kitodo.org/ruleset/v2#scheme"),
    SETTING("http://names.kitodo.org/ruleset/v2#setting"),
    SUBDIVISION_BY_DATE("http://names.kitodo.org/ruleset/v2#subdivisionByDate"),
    TYPE("http://names.kitodo.org/ruleset/v2#type"),
    UNSPECIFIED("http://names.kitodo.org/ruleset/v2#unspecified"),
    VALUE("http://names.kitodo.org/ruleset/v2#value");

    public static final String NAMESPACE = "http://names.kitodo.org/ruleset/v2#";

    private String identifier;

    private Ruleset(String identifier) {
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
