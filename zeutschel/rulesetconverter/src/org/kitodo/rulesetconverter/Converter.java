package org.kitodo.rulesetconverter;

import java.io.*;
import java.util.*;
import java.util.Map.Entry;

import org.kitodo.dataaccess.*;
import org.kitodo.dataaccess.format.xml.*;
import org.kitodo.dataaccess.storage.memory.*;
import org.kitodo.rulesetconverter.namespaces.*;
import org.xml.sax.SAXException;

public class Converter {
    static final String DEFAULT_DISPLAY_JUDGING = "http://names.kitodo.org/rulesetconverter#defaultDisplayJudging";
    static final Literal FALSE = new MemoryLiteral("false", XMLSchema.BOOLEAN);
    static final String LEGACYFIELDTYPE = "http://names.kitodo.org/rulesetconverter#legacyfieldtype";
    static final String RDF_1 = RDF.toURL(1);
    static final Literal TRUE = new MemoryLiteral("true", XMLSchema.BOOLEAN);

    void convert(File projects, File digitalCollections, File metadataDisplayRules, File opac, File processProperties,
	    File ruleset, File outputDir) throws IOException, SAXException, LinkedDataException {

	// read files
	System.out.println("Lese Dateien ...");
	Node projectsConfig = XMLReader.toNode(projects, MemoryStorage.INSTANCE);
	Node collections = XMLReader.toNode(digitalCollections, MemoryStorage.INSTANCE);
	Node displayRules = XMLReader.toNode(metadataDisplayRules, MemoryStorage.INSTANCE);
	Node opacXml = XMLReader.toNode(opac, MemoryStorage.INSTANCE);
	Node propertiesConfig = XMLReader.toNode(processProperties, MemoryStorage.INSTANCE);
	Node inRuleset = XMLReader.toNode(ruleset, MemoryStorage.INSTANCE);

	// create local namespaces
	Projects projectsNS = new Projects(Namespaces.namespaceOf(projectsConfig.getType()));
	DigitalCollections collectionsNS = new DigitalCollections(Namespaces.namespaceOf(collections.getType()));
	Opac opacNS = new Opac(Namespaces.namespaceOf(opacXml.getType()));
	ProcessProperties propertiesNS = new ProcessProperties(Namespaces.namespaceOf(propertiesConfig.getType()));
	Preferences rulesetNS = new Preferences(Namespaces.namespaceOf(inRuleset.getType()));

	// convert all projects
	Set<String> projectNames = new HashSet<>();
	for (Node project : projectsConfig.getByType(projectsNS.PROJECT).nodes()) {
	    projectNames.add(project.get(projectsNS.NAME).literal().getValue());
	}
	for (Node project : collections.getByType(collectionsNS.PROJECT).nodes()) {
	    for (Node name : project.getByType(collectionsNS.NAME).nodes()) {
		projectNames.add(name.get(RDF_1).literal().getValue());
	    }
	}
	for (String project : projectNames) {
	    System.out.println("Konvertiere Projekt " + project + "...");

	    // create data
	    Map<String, Node> divisions = new TreeMap<>(String.CASE_INSENSITIVE_ORDER);
	    Map<String, Node> keys = new TreeMap<>(new Comparator<String>() {

		    public int compare(String o1, String o2) {
		        int cmp = o1.compareToIgnoreCase(o2);
		        if (cmp != 0) return cmp;

		        return o1.compareTo(o2);
		    }
	    });
	    Map<String, Node> stages = new TreeMap<>(String.CASE_INSENSITIVE_ORDER);
	    Set<String> m_personKeys = new HashSet<>();
	    Set<String> m_doctypes = new HashSet<>();
	    Map<String, Boolean> removedivisions = new HashMap<>();

	    addKeys(inRuleset, rulesetNS, keys, m_personKeys);
	    addGroups(inRuleset, rulesetNS, keys, m_personKeys);
	    addCodomains(project, displayRules, keys, m_personKeys);
	    addDivisions(inRuleset, rulesetNS, divisions, keys, m_personKeys);
	    addDoctypes(opacXml, opacNS, divisions, m_doctypes);
	    configureNewspaperDivisions(divisions, opacNS, removedivisions);
	    addCollections(project, collections, collectionsNS, opacNS, divisions, keys);
	    configureProject(project, projectsConfig, projectsNS, divisions, keys, m_doctypes);
	    addProperties(project, propertiesConfig, propertiesNS, opacNS, divisions, keys, stages);
	    setEditingProperties(keys);
	    excludeKeysOnStages(keys, stages);
	    addCreateStage(project, projectsConfig, projectsNS, keys, stages);
	    cleanup(divisions, opacNS);

	    // prepare ruleset file
	    Node outRuleset = new MemoryNode(Ruleset.RULESET);
	    outRuleset.put(Ruleset.LANG, "en");

	    MemoryNode declaration = new MemoryNode(Ruleset.DECLARATION);
	    for (Entry<String, Node> divi : divisions.entrySet())
		if (!removedivisions.containsKey(divi.getKey())) declaration.add(divi.getValue());
	    declaration.addAll(keys.values());
	    outRuleset.add(declaration);

	    MemoryNode correlation = new MemoryNode(Ruleset.CORRELATION);
	    for (Entry<String, Node> divi : divisions.entrySet())
		if (!removedivisions.containsKey(divi.getKey()) || removedivisions.get(divi.getKey()) == false) {
		    Result restriction = divi.getValue().get(Ruleset.RESTRICTION);
		    if (restriction.isAnyNode()) {
			correlation.addAll(restriction.nodes());
			divi.getValue().removeAll(Ruleset.RESTRICTION);
		    }
		}
	    for (Node key : keys.values()) {
		Result restriction = key.get(Ruleset.RESTRICTION);
		if (restriction.isAny()) {
		    correlation.add(restriction.nodeExpectable());
		    key.removeAll(Ruleset.RESTRICTION);
		}
	    }
	    outRuleset.add(correlation);

	    MemoryNode editing = new MemoryNode(Ruleset.EDITING);
	    for (Node key : keys.values()) {
		Result setting = key.get(Ruleset.SETTING);
		if (setting.isAny()) {
		    editing.add(setting.nodeExpectable());
		    key.removeAll(Ruleset.SETTING);
		}
	    }
	    for (Node stage : stages.values())
		editing.add(stage);
	    outRuleset.add(editing);

	    // write file
	    String filename = rulesetName(ruleset) + '_' + project + ".xml";
	    System.out.println("Schreibe " + filename + "...");
	    File outfile = new File(outputDir, filename);
	    SerializationFormat.XML.write(outRuleset, null, outfile);

	    beautify(outfile);
	}
    }

    void addDoctypes(Node opacXml, Opac opacNS, Map<String, Node> divisions, Set<String> m_doctypes)
	    throws LinkedDataException {
	for (Node doctypes : opacXml.getByType(opacNS.DOCTYPES).nodes())
	    for (Node type : doctypes.getByType(opacNS.TYPE).nodes()) {
		String id = type.get(opacNS.RULESET_TYPE).literal().getValue();
		m_doctypes.add(id);
		Node division = divisions.computeIfAbsent(id, λ -> new MemoryNode(Ruleset.DIVISION));
		if (!division.get(Ruleset.ID).isAny()) {
		    division.put(Ruleset.ID, id);
		    for (Node opacXmlLabel : type.getByType(opacNS.LABEL).nodes()) {
			MemoryNode rulesetLabel = new MemoryNode(Ruleset.LABEL);
			rulesetLabel.put(RDF_1, opacXmlLabel.get(RDF_1).literal());
			String lang = opacXmlLabel.get(opacNS.LANGUAGE).literal().getValue();
			if ("rusdml".equals(lang)) lang = "ru";
			if ("en".equals(lang)) division.add(1, rulesetLabel);
			else {
			    rulesetLabel.put(Ruleset.LANG, lang);
			    division.add(rulesetLabel);
			}
		    }
		    Node restriction = new MemoryNode(Ruleset.RESTRICTION);
		    restriction.put(Ruleset.DIVISION, id);
		    restriction.put(Ruleset.UNSPECIFIED, "forbidden");
		    division.put(Ruleset.RESTRICTION, restriction);
		}

		// processing information, remove later
		division.put(opacNS.TITLE, type.get(opacNS.TITLE).literal());
		Result isNewspaper = type.get(opacNS.IS_NEWSPAPER);
		if (isNewspaper.isAnyLiteral() && isNewspaper.literalExpectable().getValue().equals("true"))
		    division.put(opacNS.IS_NEWSPAPER, TRUE);
	    }
    }

    void addKeys(Node inRuleset, Preferences rulesetNS, Map<String, Node> keys, Set<String> m_personKeys)
	    throws LinkedDataException {
	List<Node> person = new ArrayList<>();
	for (Node metadataType : inRuleset.getByType(rulesetNS.METADATA_TYPE).nodes()) {
	    String name = metadataType.getByType(rulesetNS.TITLECASE_NAME).node().get(RDF_1).literal().getValue();
	    Result type = metadataType.get(rulesetNS.TYPE);
	    if (type.isAnyLiteral() && type.literal().getValue().equals("person")) {
		Node option = new MemoryNode(Ruleset.OPTION);
		option.put(Ruleset.VALUE, name);
		for (Node language : metadataType.getByType(rulesetNS.LANGUAGE).nodes()) {
		    Node rulesetLabel = new MemoryNode(Ruleset.LABEL);
		    Result languageName = language.get(rulesetNS.LOWERCASE_NAME);
		    String lang = languageName.isAnyLiteral() ? languageName.literal().getValue() : "en";
		    rulesetLabel.add(language.get(RDF_1).literal());
		    if ("rusdml".equals(lang)) lang = "ru";
		    if ("en".equals(lang)) option.add(1, rulesetLabel);
		    else {
			rulesetLabel.put(Ruleset.LANG, lang);
			option.add(rulesetLabel);
		    }
		}
		person.add(option);
		m_personKeys.add(name);
	    } else {
		boolean metsDiv = false;
		for (int i = 1; i <= 2; i++) {
		    Node key = keys.computeIfAbsent(name, λ -> new MemoryNode(Ruleset.KEY));
		    if (!key.get(Ruleset.ID).isAny()) {
			key.put(Ruleset.ID, name);
			if (metsDiv) key.put(Ruleset.DOMAIN, "mets:div");
		    } else System.err.println("Warnung: Doppelte Definition von Metadatum: " + name);
		    for (Node language : metadataType.getByType(rulesetNS.LANGUAGE).nodes()) {
			Node rulesetLabel = new MemoryNode(Ruleset.LABEL);
			Result languageName = language.get(rulesetNS.LOWERCASE_NAME);
			String lang = languageName.isAnyLiteral() ? languageName.literal().getValue() : "en";
			String labelValue = language.get(RDF_1).literal().getValue();
			if (metsDiv) labelValue += " ‹METS›";
			rulesetLabel.removeAll(RDF_1);
			rulesetLabel.add(new MemoryLiteral(labelValue, XMLSchema.STRING));
			if ("rusdml".equals(lang)) lang = "ru";
			if ("en".equals(lang)) key.add(1, rulesetLabel);
			else {
			    rulesetLabel.put(Ruleset.LANG, lang);
			    key.add(rulesetLabel);
			}
		    }
		    if (name.equals("TitleDocMain")) {
			name = "LABEL";
			metsDiv = true;
		    } else if (name.equals("TitleDocMainShort")) {
			name = "ORDERLABEL";
			metsDiv = true;
		    } else break;
		}
	    }
	}
	// „Person“ hinzufügen
	if (!person.isEmpty()) {
	    Node personKey = new MemoryNode(Ruleset.KEY);
	    personKey.put(Ruleset.ID, "person");
	    Node labelEn = new MemoryNode(Ruleset.LABEL);
	    labelEn.put(RDF_1, "Person");
	    personKey.add(labelEn);

	    Node role = new MemoryNode(Ruleset.KEY);
	    role.put(Ruleset.ID, "role");
	    labelEn = new MemoryNode(Ruleset.LABEL);
	    labelEn.put(RDF_1, "Role");
	    role.add(labelEn);
	    Node labelDe = new MemoryNode(Ruleset.LABEL);
	    labelDe.put(Ruleset.LANG, "de");
	    labelDe.put(RDF_1, "Rolle");
	    role.add(labelDe);
	    role.addAll(person);
	    personKey.add(role);

	    Node authorityValue = new MemoryNode(Ruleset.KEY);
	    authorityValue.put(Ruleset.ID, "authorityValue");
	    labelEn = new MemoryNode(Ruleset.LABEL);
	    labelEn.put(RDF_1, "URI");
	    authorityValue.add(labelEn);
	    Node codomain = new MemoryNode(Ruleset.CODOMAIN);
	    codomain.put(Ruleset.TYPE, "anyURI");
	    authorityValue.add(codomain);
	    personKey.add(authorityValue);

	    Node lastName = new MemoryNode(Ruleset.KEY);
	    lastName.put(Ruleset.ID, "lastName");
	    labelEn = new MemoryNode(Ruleset.LABEL);
	    labelEn.put(RDF_1, "Surname");
	    lastName.add(labelEn);
	    labelDe = new MemoryNode(Ruleset.LABEL);
	    labelDe.put(Ruleset.LANG, "de");
	    labelDe.put(RDF_1, "Nachname");
	    lastName.add(labelDe);
	    personKey.add(lastName);

	    Node firstName = new MemoryNode(Ruleset.KEY);
	    firstName.put(Ruleset.ID, "firstName");
	    labelEn = new MemoryNode(Ruleset.LABEL);
	    labelEn.put(RDF_1, "First name");
	    firstName.add(labelEn);
	    labelDe = new MemoryNode(Ruleset.LABEL);
	    labelDe.put(Ruleset.LANG, "de");
	    labelDe.put(RDF_1, "Vorname");
	    firstName.add(labelDe);
	    personKey.add(firstName);

	    Node displayName = new MemoryNode(Ruleset.KEY);
	    displayName.put(Ruleset.ID, "displayName");
	    labelEn = new MemoryNode(Ruleset.LABEL);
	    labelEn.put(RDF_1, "Display name");
	    displayName.add(labelEn);
	    labelDe = new MemoryNode(Ruleset.LABEL);
	    labelDe.put(Ruleset.LANG, "de");
	    labelDe.put(RDF_1, "Anzeigename");
	    displayName.add(labelDe);
	    personKey.add(displayName);

	    keys.put("person", personKey);
	}
    }

    void addGroups(Node inRuleset, Preferences rulesetNS, Map<String, Node> keys, Set<String> m_personKeys)
	    throws LinkedDataException {
	List<String> removeKeys = new LinkedList<>();
	for (Node metadataType : inRuleset.getByType(rulesetNS.GROUP).nodes()) {
	    String name = metadataType.getByType(rulesetNS.TITLECASE_NAME).node().get(RDF_1).literal().getValue();

	    Node key = keys.computeIfAbsent(name, λ -> new MemoryNode(Ruleset.KEY));
	    if (!key.get(Ruleset.ID).isAny()) key.put(Ruleset.ID, name);
	    else System.err.println("Warnung: Doppelte Definition von Metadatum/Gruppe: " + name);
	    for (Node language : metadataType.getByType(rulesetNS.LANGUAGE).nodes()) {
		Node rulesetLabel = new MemoryNode(Ruleset.LABEL);
		Result languageName = language.get(rulesetNS.LOWERCASE_NAME);
		String lang = languageName.isAnyLiteral() ? languageName.literal().getValue() : "en";
		String labelValue = language.get(RDF_1).literal().getValue();
		rulesetLabel.removeAll(RDF_1);
		rulesetLabel.add(new MemoryLiteral(labelValue, XMLSchema.STRING));
		if ("rusdml".equals(lang)) lang = "ru";
		if ("en".equals(lang)) key.add(1, rulesetLabel);
		else {
		    rulesetLabel.put(Ruleset.LANG, lang);
		    key.add(rulesetLabel);
		}
	    }
	    for (Node metadata : metadataType.getByType(rulesetNS.METADATA).nodes()) {
		String metaName = metadata.get(RDF_1).literal().getValue();
		Node subKey = keys.get(metaName);
		removeKeys.add(metaName);
		if (subKey == null)
		    if (m_personKeys.contains(metaName) && keys.containsKey("person")) subKey = keys.get("person");
		    else {
		    System.err.println("Warnung: " + name + " referenziert undefiniertes " + metaName);
		    subKey = new MemoryNode(Ruleset.KEY);
		    subKey.put(Ruleset.ID, metaName);
		    Node subKeyLabel = new MemoryNode(Ruleset.LABEL);
		    subKeyLabel.put(RDF_1, metaName);
		    subKey.add(subKeyLabel);
		    }
		key.add(subKey);
	    }
	}
	for (String removeKey : removeKeys)
	    keys.remove(removeKey);
    }

    void addCodomains(String project, Node displayRules, Map<String, Node> keys, Set<String> m_personKeys)
	    throws LinkedDataException {
	Node ruleset = displayRules.getByType(DisplayRules.RULESET).node();
	Set<Node> projectNodes = ruleset.getByType(DisplayRules.CONTEXT, DisplayRules.PROJECT_NAME, project).nodes();
	// if bind=create
	Node projectNode = null;
	for (Node node : projectNodes) {
	    if (node.getByType(DisplayRules.BIND).node().get(RDF_1).literal().getValue().equals("create")) continue;
	    projectNode = node;
	    break;
	}
	if (projectNode == null && projectNodes.size() > 0) projectNode = projectNodes.iterator().next();
	if (projectNode == null) return;

	for (Result enumeratedEntry : projectNode.getEnumerated()) {
	    Node displayRule = enumeratedEntry.node();
	    String tagName = Namespaces.localNameOf(displayRule.getType());
	    boolean multi = true;
	    boolean allURIs = true;
	    List<String> presets = new ArrayList<>();
	    List<Node> options = new ArrayList<>();
	    Result ref = displayRule.get(DisplayRules.REF);
	    String refValue = ref.isAnyLiteral() ? ref.literal().getValue() : "";
	    switch (tagName) {
		case "select1":
		    multi = false;
		case "select":
		    for (Result itemResult : displayRule.getEnumerated()) {
			Node item = itemResult.node();
			if (!item.hasType(DisplayRules.ITEM)) continue;
			Result labelValue = item.getByType(DisplayRules.LABEL).node().get(RDF_1);
			String label = labelValue.isAnyLiteral() ? labelValue.literal().getValue()
				: labelValue.identifiableNode().getIdentifier();
			Result valueValue = item.getByType(DisplayRules.VALUE).node().get(RDF_1);
			String value = "";
			if (valueValue.isAnyLiteral()) {
			    allURIs = false;
			    value = valueValue.literal().getValue();
			} else if (valueValue.isAnyIdentifiableNode())
			    value = valueValue.identifiableNode().getIdentifier();
			if (!value.isEmpty()) {
			    Node option = new MemoryNode(Ruleset.OPTION);
			    option.put(Ruleset.VALUE, value);
			    if (!value.equals(label)) {
				Node labelNode = new MemoryNode(Ruleset.LABEL);
				labelNode.put(RDF_1, label);
				option.add(labelNode);
			    }
			    options.add(option);
			    Result selected = item.get(DisplayRules.SELECTED);
			    if (selected.isAnyLiteral() && selected.literalExpectable().getValue().equals("true"))
				presets.add(value);
			}
		    }
		    if (options.size() == 1) {
			Node codomain = new MemoryNode(Ruleset.CODOMAIN);
			codomain.put(Ruleset.TYPE, "boolean");
			Node key = keys.computeIfAbsent(refValue, λ -> new MemoryNode(Ruleset.KEY));
			key.add(codomain);
		    } else if (options.size() > 0 && allURIs) {
			Node codomain = new MemoryNode(Ruleset.CODOMAIN);
			codomain.put(Ruleset.TYPE, "anyURI");
			Node key = keys.computeIfAbsent(refValue, λ -> new MemoryNode(Ruleset.KEY));
			key.add(codomain);
		    }
		    if (options.size() > 0) {
			Node key = keys.computeIfAbsent(refValue, λ -> new MemoryNode(Ruleset.KEY));
			if (!key.get(Ruleset.ID).isAny()) key.put(Ruleset.ID, refValue);
			key.addAll(options);
			if (multi == false && presets.size() > 1) presets = Arrays.asList(presets.get(0));
			for (String presetValue : presets) {
			    Node preset = new MemoryNode(Ruleset.PRESET);
			    preset.put(RDF_1, presetValue);
			    key.add(preset);
			}
		    }
		default:
		    Node key = keys.get(m_personKeys.contains(refValue) ? "person" : refValue);
		    if (key != null) {
			Result settingResult = key.get(Ruleset.SETTING);
			if (!settingResult.isAny()) {
			    Node newSetting = new MemoryNode(Ruleset.SETTING);
			    newSetting.put(Ruleset.KEY, m_personKeys.contains(refValue) ? "person" : refValue);
			    key.put(Ruleset.SETTING, newSetting);
			    settingResult = key.get(Ruleset.SETTING);
			}
			Node setting = settingResult.node();
			setting.put(LEGACYFIELDTYPE, tagName);
		    }
		break;
	    }
	}
    }

    void addDivisions(Node inRuleset, Preferences rulesetNS, Map<String, Node> divisions, Map<String, Node> keys,
	    Set<String> m_personKeys) throws LinkedDataException {
	for (Node docStrctType : inRuleset.getByType(rulesetNS.DOC_STRCT_TYPE).nodes()) {
	    // declaration
	    String name = docStrctType.getByType(rulesetNS.TITLECASE_NAME).node().get(RDF_1).literal().getValue();
	    Node division = divisions.computeIfAbsent(name, λ -> new MemoryNode(Ruleset.DIVISION));
	    if (!division.get(Ruleset.ID).isAny()) division.put(Ruleset.ID, name);
	    if (division.getByType(Ruleset.LABEL).isAny())
		System.err.println("Warnung: Doppelte Definition von Struktur: " + name);
	    for (Node language : docStrctType.getByType(rulesetNS.LANGUAGE).nodes()) {
		Node rulesetLabel = new MemoryNode(Ruleset.LABEL);
		Result languageName = language.get(rulesetNS.LOWERCASE_NAME);
		String lang = languageName.isAnyLiteral() ? languageName.literal().getValue() : "en";
		rulesetLabel.add(language.get(RDF_1).literal());
		if ("rusdml".equals(lang)) lang = "ru";
		if ("en".equals(lang)) division.add(1, rulesetLabel);
		else {
		    rulesetLabel.put(Ruleset.LANG, lang);
		    division.add(rulesetLabel);
		}
	    }

	    // restriction
	    Node restriction = new MemoryNode(Ruleset.RESTRICTION);
	    restriction.put(Ruleset.DIVISION, name);
	    restriction.put(Ruleset.UNSPECIFIED, "forbidden");
	    String num = null;
	    Node personRestriction = null;
	    for (Result children : docStrctType.getEnumerated()) {
		if (!children.isAnyNode()) continue; // misplaced text
		Node child = children.node();
		Node permit = new MemoryNode(Ruleset.PERMIT);
		String value = child.get(RDF_1).literal().getValue();
		switch (Namespaces.localNameOf(child.getType())) {
		    case "allowedchildtype":
			permit.put(Ruleset.DIVISION, value);
			restriction.add(permit);
		    break;
		    case "metadata":
		    case "group":
			if (m_personKeys.contains(value)) {
			    if (personRestriction == null) {
				permit.put(Ruleset.KEY, "person");
				personRestriction = new MemoryNode(Ruleset.PERMIT);
				personRestriction.put(Ruleset.KEY, "role");
				personRestriction.put(Ruleset.UNSPECIFIED, "forbidden");
				permit.add(personRestriction);
				restriction.add(permit);
			    }
			    Node permitOption = new MemoryNode(Ruleset.PERMIT);
			    permitOption.put(Ruleset.VALUE, value);
			    personRestriction.add(permitOption);
			} else {
			    permit.put(Ruleset.KEY, value);
			    num = child.get(rulesetNS.NUM).literal().getValue();
			    switch (num) {
				case "+":
				    permit.put(Ruleset.MIN_OCCURS, "1");
				break;
				case "1m":
				    permit.put(Ruleset.MIN_OCCURS, "1");
				case "1o":
				    permit.put(Ruleset.MAX_OCCURS, "1");
				default:
			    }
			    restriction.add(permit);
			}
			// editing
			Node key = keys.get(m_personKeys.contains(value) ? "person" : value);
			if (key == null)
			    System.err.println("Warnung: " + name + " referenziert undefiniertes " + value);
			else {
			    Result settingResult = key.get(Ruleset.SETTING);
			    if (!settingResult.isAny()) {
				Node newSetting = new MemoryNode(Ruleset.SETTING);
				newSetting.put(Ruleset.KEY, m_personKeys.contains(value) ? "person" : value);
				key.put(Ruleset.SETTING, newSetting);
				settingResult = key.get(Ruleset.SETTING);
			    }
			    Node setting = settingResult.node();
			    Result result = setting.get(DEFAULT_DISPLAY_JUDGING);
			    int defaultDisplayTrue = 0;
			    int defaultDisplayFalse = 0;
			    if (result.isAny()) {
				String[] b = result.identifiableNode().getIdentifier().split(":", 2);
				defaultDisplayTrue = Integer.valueOf(b[0]);
				defaultDisplayFalse = Integer.valueOf(b[1]);
			    }
			    Result defaultDisplay = child.get(rulesetNS.DEFAULT_DISPLAY);
			    if (defaultDisplay.isAnyLiteral() && defaultDisplay.literal().getValue().equals("true"))
				defaultDisplayTrue += 1;
			    else defaultDisplayFalse += 1;
			    setting.removeAll(DEFAULT_DISPLAY_JUDGING);
			    setting.put(DEFAULT_DISPLAY_JUDGING, defaultDisplayTrue + ":" + defaultDisplayFalse);
			}
		    break;
		    default:
			continue;
		}
		switch (value) {
		    case "TitleDocMain":
			permit = new MemoryNode(Ruleset.PERMIT);
			permit.put(Ruleset.KEY, "LABEL");
			permit.put(Ruleset.MAX_OCCURS, "1");
			if ("+".equals(num) || "1m".equals(num)) permit.put(Ruleset.MIN_OCCURS, "1");
			restriction.add(permit);
		    break;
		    case "TitleDocMainShort":
			permit = new MemoryNode(Ruleset.PERMIT);
			permit.put(Ruleset.KEY, "ORDERLABEL");
			permit.put(Ruleset.MAX_OCCURS, "1");
			if ("+".equals(num) || "1m".equals(num)) permit.put(Ruleset.MIN_OCCURS, "1");
			restriction.add(permit);
		}
	    }
	    division.put(Ruleset.RESTRICTION, restriction);
	}
    }

    void configureNewspaperDivisions(Map<String, Node> divisions, Opac opacNS, Map<String, Boolean> removedivisions)
	    throws LinkedDataException {
	for (Node newspaper : divisions.values())
	    if (newspaper.get(opacNS.IS_NEWSPAPER).isAny()) {
		Node sbd = new MemoryNode(Ruleset.SUBDIVISION_BY_DATE);
		Result firstRestriction = newspaper.get(Ruleset.RESTRICTION).node().get(RDF_1);
		if (!firstRestriction.isAnyNode()) return;
		String yearName = firstRestriction.node().get(Ruleset.DIVISION).literal().getValue();
		Node year = divisions.get(yearName);
		removedivisions.put(yearName, true);
		Node newYear = new MemoryNode(Ruleset.DIVISION);
		newYear.put(Ruleset.ID, year.get(Ruleset.ID).literal());
		newYear.put(Ruleset.DATES, "TitleDocMain");
		newYear.put(Ruleset.SCHEME, "yyyy");
		sbd.add(newYear);

		String monthName = year.get(Ruleset.RESTRICTION).node().get(RDF_1).node().get(Ruleset.DIVISION)
			.literal().getValue();
		Node month = divisions.get(monthName);
		removedivisions.put(monthName, true);
		Node newMonth = new MemoryNode(Ruleset.DIVISION);
		newMonth.put(Ruleset.ID, month.get(Ruleset.ID).literal());
		newMonth.put(Ruleset.DATES, "TitleDocMainShort");
		newMonth.put(Ruleset.SCHEME, "M");
		sbd.add(newMonth);

		Result monthFirstChildDivision = month.get(Ruleset.RESTRICTION).node().get(RDF_1).node()
			.get(Ruleset.DIVISION);
		if (monthFirstChildDivision.isAnyLiteral()) {
		    String dayName = monthFirstChildDivision.literal().getValue();
		    Node day = divisions.get(dayName);
		    removedivisions.put(dayName, false);
		    Node newDay = new MemoryNode(Ruleset.DIVISION);
		    newDay.put(Ruleset.ID, day.get(Ruleset.ID).literal());
		    newDay.put(Ruleset.DATES, "TitleDocMainShort");
		    newDay.put(Ruleset.SCHEME, "d");
		    sbd.add(newDay);
		}

		newspaper.add(sbd);
	    }
    }

    void addCollections(String project, Node collections, DigitalCollections collectionsNS, Opac opacNS,
	    Map<String, Node> divisions, Map<String, Node> keys) throws LinkedDataException {

	Node collList = null;
	// gehe die Projekte durch ob es ein solches gibt
	for (Node proj : collections.getByType(collectionsNS.PROJECT).nodes()) {
	    for (Node name : proj.getByType(collectionsNS.NAME).nodes()) {
		if (name.get(RDF_1).literal().getValue().equals(project)) {
		    collList = proj;
		    break;
		}
	    }
	}
	// sonst die defaults nehmen
	if (collList == null) {
	    Result byType = collections.getByType(collectionsNS.DEFAULT);
	    if (byType.isAnyNode()) collList = byType.node();
	    else return;
	}

	List<String> all = new ArrayList<>();
	List<String> preselected = new ArrayList<>();
	for (Node coll : collList.getByType(collectionsNS.DIGITAL_COLLECTION).nodes()) {
	    String v = coll.get(RDF_1).literal().getValue();
	    all.add(v);
	    Result d = coll.get(collectionsNS.DEFAULT);
	    if (d.isAnyLiteral() && d.literal().getValue().equals("true")) preselected.add(v);
	}

	Node singleDigCollection = new MemoryNode(Ruleset.KEY);
	singleDigCollection.put(Ruleset.ID, "singleDigCollection");
	Node labelEn = new MemoryNode(Ruleset.LABEL);
	labelEn.put(RDF_1, "Digital collections");
	singleDigCollection.add(labelEn);
	Node labelDe = new MemoryNode(Ruleset.LABEL);
	labelDe.put(RDF_1, "Digitale Kollektionen");
	labelDe.put(Ruleset.LANG, "de");
	singleDigCollection.add(labelDe);
	for (String c : all) {
	    Node option = new MemoryNode(Ruleset.OPTION);
	    option.put(Ruleset.VALUE, c);
	    singleDigCollection.add(option);
	}
	for (String c : preselected) {
	    Node preset = new MemoryNode(Ruleset.PRESET);
	    preset.put(RDF_1, c);
	    singleDigCollection.add(preset);
	}
	keys.put("singleDigCollection", singleDigCollection);
	// Zulässigkeit
	for (Node opacKey : divisions.values()) {
	    Result opacTitle = opacKey.get(opacNS.TITLE);
	    if (opacTitle.isAny()) {
		Node restriction = opacKey.get(Ruleset.RESTRICTION).node();
		Node permit = new MemoryNode(Ruleset.PERMIT);
		permit.put(Ruleset.KEY, "singleDigCollection");
		restriction.add(permit);
	    }
	}
    }

    void configureProject(String project, Node projectsConfig, Projects projectsNS, Map<String, Node> divisions,
	    Map<String, Node> keys, Set<String> m_doctypes) throws LinkedDataException {
	for (Node proj : projectsConfig.getByType(projectsNS.PROJECT).nodes()) {
	    if (!project.equals(proj.get(projectsNS.NAME).literal().getValue())) continue;
	    Node itemlist = proj.getByType(projectsNS.CREATE_NEW_PROCESS).node().getByType(projectsNS.ITEMLIST).node();
	    for (Result itemResult : itemlist.getEnumerated()) {
		if(!itemResult.isAnyNode()) continue;
		Node item = itemResult.node();
		if (!item.hasType(projectsNS.ITEM)) continue;
		Result result = item.get(projectsNS.FROM);
		String from = result.isAnyLiteral() ? result.literal().getValue() : "prozess";
		HashSet<String> doctypes = new HashSet<>(m_doctypes);
		Result isnotdoctype = item.get(projectsNS.ISNOTDOCTYPE);
		if (isnotdoctype.isAnyLiteral())
		    doctypes.removeAll(Arrays.asList(isnotdoctype.literal().getValue().split("\\|")));
		Result isdoctype = item.get(projectsNS.ISDOCTYPE);
		if (isdoctype.isAnyLiteral())
		    doctypes.addAll(Arrays.asList(isdoctype.literal().getValue().split("\\|")));
		Result requiredResult = item.get(projectsNS.REQUIRED);
		boolean required = requiredResult.isAnyLiteral() && requiredResult.literal().getValue().equals("true");
		Result docstructResult = item.get(projectsNS.DOCSTRUCT);
		boolean firstchild = docstructResult.isAnyLiteral()
			&& docstructResult.literal().getValue().equals("firstchild");
		Result metadataResult = item.get(projectsNS.METADATA);
		String metadata = metadataResult.isAnyLiteral() ? metadataResult.literal().getValue() : "";
		String label = item.get(RDF_1).literal().getValue();

		// gibt es das Metadatum?
		Node md = keys.get(metadata);
		String finalMetadataName = !metadata.isEmpty() ? metadata : label;
		if (md == null) {
		    md = new MemoryNode(Ruleset.KEY);
		    md.put(Ruleset.ID, finalMetadataName);
		    md.removeAll(Ruleset.DOMAIN);
		    md.put(Ruleset.DOMAIN, "technical");
		    keys.put(finalMetadataName, md);
		} else switch (from) {
		    case "vorlage":
			md.removeAll(Ruleset.DOMAIN);
			md.put(Ruleset.DOMAIN, "source");
		    break;
		    case "prozess":
			md.removeAll(Ruleset.DOMAIN);
			md.put(Ruleset.DOMAIN, "technical");
		    break;
		}
		boolean foundLabel = false;
		for (Node labelNode : md.getByType(Ruleset.LABEL).nodes())
		    if (labelNode.get(RDF_1).literal().getValue().equals(label)) {
			foundLabel = true;
			break;
		    }
		if (!foundLabel) {
		    Node mdl = new MemoryNode(Ruleset.LABEL);
		    mdl.put(RDF_1, label);
		    md.add(mdl);
		}
		// select elements
		for (Node select : item.getByType(projectsNS.SELECT).nodes()) {
		    String value = select.get(RDF_1).literal().getValue();
		    Result option = md.getByType(Ruleset.OPTION, Ruleset.VALUE, value);
		    if (!option.isAny()) {
			Node newOption = new MemoryNode(Ruleset.OPTION);
			newOption.put(Ruleset.VALUE, value);
			Result selectLabel = select.get(projectsNS.LABEL);
			if (selectLabel.isAnyLiteral()) {
			    Node newOptionLabel = new MemoryNode(Ruleset.LABEL);
			    newOptionLabel.put(RDF_1, selectLabel.literal());
			    newOption.add(newOptionLabel);
			}
			md.add(newOption);
		    }
		}
		// required/allowed for doctypes
		for (String outerDoctype : doctypes) {
		    List<String> innerDoctypes = Arrays.asList(outerDoctype);
		    if (firstchild) {
			innerDoctypes = new ArrayList<>();
			Node node = divisions.get(outerDoctype);
			if(node != null){
			for (Node permit : node.get(Ruleset.RESTRICTION).node().getByType(Ruleset.PERMIT).nodes()) {
			    Result division = permit.get(Ruleset.DIVISION);
			    if (!division.isAnyLiteral()) continue;
			    innerDoctypes.add(division.literal().getValue());
			}
			}
		    }
		    for (String doctype : innerDoctypes) {
			boolean found = false;
			Node doctypeDivison = divisions.get(doctype);
			if (doctypeDivison == null) {
			    doctypeDivison = new MemoryNode(Ruleset.DIVISION);
			    doctypeDivison.put(Ruleset.ID, doctype);
			    Node dtLabel = new MemoryNode(Ruleset.LABEL);
			    dtLabel.put(RDF_1, doctype);
			    doctypeDivison.add(dtLabel);
			    divisions.put(doctype, doctypeDivison);
			}
			Result restrictionResult = doctypeDivison.get(Ruleset.RESTRICTION);
			if (!restrictionResult.isAny()) {
			    Node restrictionNode = new MemoryNode(Ruleset.RESTRICTION);
			    restrictionNode.put(Ruleset.DIVISION, doctype);
			    restrictionNode.put(Ruleset.UNSPECIFIED, "forbidden");
			    doctypeDivison.put(Ruleset.RESTRICTION, restrictionNode);
			    restrictionResult = doctypeDivison.get(Ruleset.RESTRICTION);
			}
			for (Node restrictionNode : restrictionResult.nodes()) {
			    for (Node permit : restrictionNode
				    .getByType(Ruleset.PERMIT).nodes()) {
				Result permitKey = permit.get(Ruleset.KEY);
				if (!permitKey.isAnyLiteral()) continue;
				if (!permitKey.literal().getValue().equals(finalMetadataName)) continue;
				found = true;
				Result minOccursResult = permit.get(Ruleset.MIN_OCCURS);
				if (minOccursResult.isAnyLiteral()) {
				    int minOccurs = Integer.parseInt(minOccursResult.literal().getValue());
				    if (minOccurs < (required ? 1 : 0))
					minOccurs = (required ? 1 : 0);
				    permit.removeAll(Ruleset.MIN_OCCURS);
				    permit.put(Ruleset.MIN_OCCURS, Integer.toString(minOccurs));
				} else if (required) permit.put(Ruleset.MIN_OCCURS, "1");
				break;
			    }
			    if (!found) {
				Node permit = new MemoryNode(Ruleset.PERMIT);
				permit.put(Ruleset.KEY, finalMetadataName);
				if (required) permit.put(Ruleset.MIN_OCCURS, "1");
				restrictionNode.add(permit);
			    }
			}
		    }
		}
	    }
	    break;
	}
    }

    void addProperties(String project, Node propertiesConfig, ProcessProperties propertiesNS, Opac opacNS,
	    Map<String, Node> divisions, Map<String, Node> keys, Map<String, Node> stages) throws LinkedDataException {
	for (Node property : propertiesConfig.getByType(propertiesNS.PROPERTY).nodes())
	    // is project?
	    for (Node projN : property.getByType(propertiesNS.PROJECT).nodes()) {
		if (!projN.get(RDF_1).literal().getValue().equals(project)) continue;

		// gehört zum Projekt
		String name = property.get(propertiesNS.NAME).literal().getValue();
		if (!keys.containsKey(name)) {
		    Node key = new MemoryNode(Ruleset.KEY);
		    key.put(Ruleset.ID, name);
		    Node label = new MemoryNode(Ruleset.LABEL);
		    label.put(RDF_1, name);
		    key.add(label);
		    keys.put(name, key);
		}
		Node key = keys.get(name);
		key.removeAll(Ruleset.DOMAIN);
		key.put(Ruleset.DOMAIN, "technical");
		// codomain
		boolean repeatable = false;
		Result type = property.getByType(propertiesNS.TYPE);
		if (type.isAnyLiteral()) switch (type.literal().getValue()) {
		    case "listmultiselect":
			repeatable = true;
		    break;
		    case "boolean":
			Node codomain = new MemoryNode(Ruleset.CODOMAIN);
			codomain.put(Ruleset.TYPE, "boolean");
			key.add(codomain);
		    break;
		    case "date":
			codomain = new MemoryNode(Ruleset.CODOMAIN);
			codomain.put(Ruleset.TYPE, "date");
			key.add(codomain);
		    break;
		    case "number":
			codomain = new MemoryNode(Ruleset.CODOMAIN);
			codomain.put(Ruleset.TYPE, "integer");
			key.add(codomain);
		    break;
		    case "link":
			codomain = new MemoryNode(Ruleset.CODOMAIN);
			codomain.put(Ruleset.TYPE, "anyURI");
			key.add(codomain);
		    break;
		    default:
		}
		// options
		for (Node value : property.getByType(propertiesNS.VALUE).nodes()) {
		    Node option = new MemoryNode(Ruleset.OPTION);
		    option.put(RDF_1, value.get(RDF_1).literal());
		    key.add(option);
		}

		// pattern
		for (Node value : property.getByType(propertiesNS.VALIDATION).nodes()) {
		    Node option = new MemoryNode(Ruleset.PATTERN);
		    option.put(RDF_1, value.get(RDF_1).literal());
		    key.add(option);
		}
		// preset
		for (Node value : property.getByType(propertiesNS.DEFAULTVALUE).nodes()) {
		    Node option = new MemoryNode(Ruleset.PRESET);
		    option.put(RDF_1, value.get(RDF_1).literal());
		    key.add(option);
		}
		// Zulässigkeit
		for (Node opacKey : divisions.values()) {
		    Result opacTitle = opacKey.get(opacNS.TITLE);
		    if (opacTitle.isAny()) {
			Node restriction = opacKey.get(Ruleset.RESTRICTION).node();
			Node permit = new MemoryNode(Ruleset.PERMIT);
			permit.put(Ruleset.KEY, name);
			if (!repeatable) permit.put(Ruleset.MAX_OCCURS, "1");
			restriction.add(permit);
		    }
		}
		// Sichtbarkeit
		Node setting = new MemoryNode(Ruleset.SETTING);
		setting.put(Ruleset.KEY, name);
		setting.put(Ruleset.EXCLUDED, TRUE);
		setting.put(LEGACYFIELDTYPE, "text");
		key.put(Ruleset.SETTING, setting);
		for (Node value : property.getByType(propertiesNS.SHOW_STEP).nodes()) {
		    Node asSetting = new MemoryNode(Ruleset.SETTING);
		    asSetting.put(Ruleset.KEY, name);
		    asSetting.put(Ruleset.EXCLUDED, FALSE);
		    String stageName = value.get(propertiesNS.NAME).literal().getValue();
		    if ("read".equals(value.get(propertiesNS.ACCESS).literal().getValue()))
			asSetting.put(Ruleset.EDITABLE, FALSE);
		    stages.computeIfAbsent(stageName, λ -> {
			Node as = new MemoryNode(Ruleset.ACQUISITION_STAGE);
			as.put(Ruleset.NAME, λ);
			return as;
		    }).add(asSetting);
		}
		for (Node value : property.getByType(propertiesNS.SHOW_PROCESS_GROUP).nodes()) {
		    Node asSetting = new MemoryNode(Ruleset.SETTING);
		    asSetting.put(Ruleset.KEY, name);
		    asSetting.put(Ruleset.EXCLUDED, FALSE);
		    String stageName = "processGroup";
		    if ("read".equals(value.get(propertiesNS.ACCESS).literal().getValue()))
			asSetting.put(Ruleset.EDITABLE, FALSE);
		    stages.computeIfAbsent(stageName, λ -> {
			Node as = new MemoryNode(Ruleset.ACQUISITION_STAGE);
			as.put(Ruleset.NAME, λ);
			return as;
		    }).add(asSetting);
		    break;
		}
		break;
	    }
    }

    void setEditingProperties(Map<String, Node> keys) throws LinkedDataException {
	for (Node key : keys.values()) {
	    Result settingResult = key.get(Ruleset.SETTING);
	    if (!settingResult.isAny()) {
		Node newSetting = new MemoryNode(Ruleset.SETTING);
		newSetting.put(Ruleset.KEY, key.get(Ruleset.ID).literal());
		key.put(Ruleset.SETTING, newSetting);
		settingResult = key.get(Ruleset.SETTING);
	    }
	    Node setting = settingResult.node();

	    // alwaysShowing
	    Result result = setting.get(DEFAULT_DISPLAY_JUDGING);
	    int defaultDisplayTrue = 0;
	    int defaultDisplayFalse = 0;
	    if (result.isAny()) {
		String[] b = result.identifiableNode().getIdentifier().split(":", 2);
		defaultDisplayTrue = Integer.valueOf(b[0]);
		defaultDisplayFalse = Integer.valueOf(b[1]);
	    }
	    if (defaultDisplayTrue >= defaultDisplayFalse && defaultDisplayTrue > 0)
		setting.put(Ruleset.ALWAYS_SHOWING, TRUE);
	    setting.removeAll(DEFAULT_DISPLAY_JUDGING);

	    result = setting.get(LEGACYFIELDTYPE);
	    String f = "textarea";
	    if (result.isAny()) f = result.literal().getValue();
	    switch (f) {
		case "select":
		case "select1":
		case "textarea":
		    setting.put(Ruleset.MULTILINE, TRUE);
		break;
		case "readonly":
		    setting.put(Ruleset.EDITABLE, FALSE);
		break;
		default:
	    }
	    setting.removeAll(LEGACYFIELDTYPE);
	}
    }

    void excludeKeysOnStages(Map<String, Node> keys, Map<String, Node> stages) {
	for (Node stage : stages.values()) {
	    Map<String, Node> stageMap = new TreeMap<>(String.CASE_INSENSITIVE_ORDER);
	    for (Node setting : stage.getByType(Ruleset.SETTING).nodes())
		stageMap.put(setting.get(Ruleset.KEY).literalExpectable().getValue(), setting);
	    for (Node removeme : stageMap.values())
		stage.remove(removeme);
	    for (String key : keys.keySet())
		if (!stageMap.containsKey(key)) {
		    Node n = new MemoryNode(Ruleset.SETTING);
		    n.put(Ruleset.KEY, key);
		    n.put(Ruleset.EXCLUDED, TRUE);
		    stageMap.put(key, n);
		}
	    stage.addAll(stageMap.values());
	}
    }

    void addCreateStage(String project, Node projectsConfig, Projects projectsNS, Map<String, Node> keys,
	    Map<String, Node> stages) throws LinkedDataException {
	Set<String> allowed = new HashSet<>();
	for (Node proj : projectsConfig.getByType(projectsNS.PROJECT).nodes()) {
	    if (!project.equals(proj.get(projectsNS.NAME).literal().getValue())) continue;
	    Node itemlist = proj.getByType(projectsNS.CREATE_NEW_PROCESS).node().getByType(projectsNS.ITEMLIST).node();
	    for (Node item : itemlist.getByType(projectsNS.ITEM).nodes()) {
		Result metadata = item.get(projectsNS.METADATA);
		if (metadata.isAnyLiteral()) allowed.add(metadata.literal().getValue());
	    }
	}
	Node create = new MemoryNode(Ruleset.ACQUISITION_STAGE);
	create.put(Ruleset.NAME, "create");
	for (String key : keys.keySet())
	    if (!allowed.contains(key)) {
		Node exclude = new MemoryNode(Ruleset.SETTING);
		exclude.put(Ruleset.KEY, key);
		exclude.put(Ruleset.EXCLUDED, TRUE);
		create.add(exclude);
	    }
	stages.put("create", create);
    }

    void cleanup(Map<String, Node> keys, Opac opacNS) {
	for (Node key : keys.values()) {
	    Set<String> relations = new HashSet<>(key.getRelations());
	    for (String rel : relations)
		if (rel.startsWith(opacNS.NAMESPACE)) key.removeAll(rel);
	}
    }

    String rulesetName(File ruleset) {
	String result = ruleset.getPath();
	int pos = result.lastIndexOf(File.separatorChar);
	if (pos > -1) result = result.substring(pos + 1);
	pos = result.lastIndexOf('.');
	if (pos > -1) result = result.substring(0, pos);
	return result;
    }

    void beautify(File outfile) throws IOException {
	Scanner in = new Scanner(outfile);
	ArrayList<String> lines = new ArrayList<>();
	while (in.hasNextLine())
	    lines.add(in.nextLine());
	in.close();
	for (int i = 0; i < lines.size(); i++)
	    lines.set(i, lines.get(i).replace("xmlns:a=", "xmlns=").replaceAll("(?<=</?)a:", ""));
	FileWriter out = new FileWriter(outfile);
	for (String str : lines) {
	    out.write(str);
	    out.write(System.lineSeparator());
	}
	out.close();
    }
}
