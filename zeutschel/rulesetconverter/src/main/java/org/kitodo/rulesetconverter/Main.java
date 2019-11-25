package org.kitodo.rulesetconverter;

import java.io.File;

public class Main {
    public static void main(String[] args) {

        File projects = new File("/path/to/goobi_projects.xml");
        File digitalCollections = new File(
                "/path/to/goobi_digitalCollections.xml");
        File metadataDisplayRules = new File(
                "/path/to/goobi_metadataDisplayRules.xml");
        File opac = new File("/path/to/goobi_opac.xml");
        File processProperties = new File("/path/to/goobi_processProperties.xml");
        File ruleset = new File("/path/to/subhh_neu.xml");
        File out = new File("/path/to/out"); // directory, must exist

        try {
            Converter converter = new Converter();
            converter.convert(projects, digitalCollections, metadataDisplayRules,
                    opac, processProperties, ruleset, out);
            System.err.println(System.lineSeparator() + "OK");
        } catch (Exception e) {
            e.printStackTrace();
            System.err.println(System.lineSeparator() + "Error: " +
                    e.getLocalizedMessage());
        }
    }
}
