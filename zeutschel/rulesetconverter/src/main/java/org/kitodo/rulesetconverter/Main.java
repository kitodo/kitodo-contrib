/*
 * This file is licensed under GNU General Public License version 3 or later.
 */
package org.kitodo.rulesetconverter;

import org.apache.commons.cli.*;

import java.io.File;

public class Main {

    private static final String PROJECTS = "projects";
    private static final String DIGITALCOLLECTIONS = "digitalCollection";
    private static final String METADATADISPLAYRULES = "metadataDisplayRules";
    private static final String OPAC = "opac";
    private static final String PROCESSPROPERTIES = "processProperties";
    private static final String RULESET = "ruleset";
    private static final String OUTPUTDIRECTORY = "outputDirectory";

    public static void main(String[] args) {

        CommandLineParser parser = new DefaultParser();
        Options options = prepareOptions();

        try {
            CommandLine commandLine = parser.parse(prepareOptions(), args);

            if (commandLine.hasOption("help")) {
                showHelp(options);
                return;
            }

            File projects = new File(commandLine.getParsedOptionValue(PROJECTS).toString());
            File digitalCollections = new File(commandLine.getParsedOptionValue(DIGITALCOLLECTIONS).toString());
            File metadataDisplayRules = new File(commandLine.getParsedOptionValue(METADATADISPLAYRULES).toString());
            File opac = new File(commandLine.getParsedOptionValue(OPAC).toString());
            File processProperties = new File(commandLine.getParsedOptionValue(PROCESSPROPERTIES).toString());
            File ruleset = new File(commandLine.getParsedOptionValue(RULESET).toString());
            File out = new File(commandLine.getParsedOptionValue(OUTPUTDIRECTORY).toString()); // directory, must exist

            Converter converter = new Converter();
            converter.convert(projects, digitalCollections, metadataDisplayRules,
                    opac, processProperties, ruleset, out);
            System.err.println(System.lineSeparator() + "OK");
        } catch (ParseException e) {
            System.out.println(e.getMessage());
            showHelp(options);
        } catch (Exception e) {
            e.printStackTrace();
            System.err.println(System.lineSeparator() + "Error: " +
                    e.getLocalizedMessage());
        }
    }

    private static void showHelp(Options options) {
        new HelpFormatter().printHelp("rulesetconverter", options);
    }

    private static Options prepareOptions() {
        Options options = new Options();

        options.addOption(getProjectsOption())
                .addOption(getDigitalCollectionOption())
                .addOption(getMetadataDisplayRuleOption())
                .addOption(getOpacOption())
                .addOption(getProcessPropertiesOption())
                .addOption(getRulesetOption())
                .addOption(getOutputDirectoryOption())
                .addOption(getHelpOption());

        return options;
    }

    private static Option getProjectsOption() {
        return Option.builder("p")
                .required()
                .desc("Path to and file name of to be used goobi_projects.xml")
                .longOpt(PROJECTS)
                .type(String.class)
                .hasArg()
                .build();
    }

    private static Option getDigitalCollectionOption() {
        return Option.builder("dc")
                .required()
                .desc("Path to and file name of to be used goobi_digitalCollections.xml")
                .longOpt(DIGITALCOLLECTIONS)
                .type(String.class)
                .hasArg()
                .build();
    }

    private static Option getMetadataDisplayRuleOption() {
        return Option.builder("md")
                .required()
                .desc("Path to and file name of to be used goobi_metadataDisplayRules.xml")
                .longOpt(METADATADISPLAYRULES)
                .type(String.class)
                .hasArg()
                .build();
    }

    private static Option getOpacOption() {
        return Option.builder("oc")
                .required()
                .desc("Path to and file name of to be used goobi_opac.xml")
                .longOpt(OPAC)
                .type(String.class)
                .hasArg()
                .build();
    }

    private static Option getProcessPropertiesOption() {
        return Option.builder("pp")
                .required()
                .desc("Path to and file name of to be used goobi_processProperties.xml")
                .longOpt(PROCESSPROPERTIES)
                .type(String.class)
                .hasArg()
                .build();
    }

    private static Option getRulesetOption() {
        return Option.builder("r")
                .required()
                .desc("Path to and file name of to be used ruleset file")
                .longOpt(RULESET)
                .type(String.class)
                .hasArg()
                .build();
    }

    private static Option getOutputDirectoryOption() {
        return Option.builder("od")
                .required()
                .desc("Path to an existing directory where output get stored")
                .longOpt(OUTPUTDIRECTORY)
                .type(String.class)
                .hasArg()
                .build();
    }

    private static Option getHelpOption() {
        return Option.builder("h")
                .desc("Show help / usage of program")
                .longOpt("help")
                .build();
    }

}
