package com.covisint.raml;

/*
 * Copyright 2001-2005 The Apache Software Foundation.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import java.io.BufferedWriter;
import java.io.File;
import java.io.FileNotFoundException;
import java.io.FileWriter;
import java.io.IOException;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.HashSet;
import java.util.Iterator;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Map.Entry;

import org.apache.maven.plugin.AbstractMojo;
import org.apache.maven.plugin.MojoExecutionException;
import org.raml.emitter.RamlEmitter;
import org.raml.model.Action;
import org.raml.model.ActionType;
import org.raml.model.Raml;
import org.raml.model.Resource;
import org.raml.model.Response;
import org.raml.model.parameter.Header;
import org.raml.parser.visitor.RamlDocumentBuilder;

/**
 * Goal which touches a timestamp file.
 * 
 * @goal generate-raml
 * 
 * @phase process-sources
 */
public class GenerateRAMLMojo extends AbstractMojo {
	/**
	 * Location of the file.
	 * 
	 * @parameter expression="${project.build.directory}/raml"
	 * @required
	 */
	private File outputDirectory;

	/**
	 * Location of the file.
	 * 
	 * @parameter expression="${basedir}/api-doc/raml/"
	 * @required
	 */
	private File inputDirectory;

	private int majorVer = 0, minorVer = 0;
	private int firstNo = 0, secondNo = 0;
	private int verComp = 0;

	public void execute() throws MojoExecutionException {
		System.out.println("---Enter direactory---");
		File f = outputDirectory;

		if (!f.exists()) {
			f.mkdirs();
		}

		String ramlResourceToFetch = inputDirectory.getAbsolutePath();

		File folder = new File(ramlResourceToFetch);
		File[] listOfFiles = folder.listFiles();

		HashSet<Float> ramlFlolders = ramlVersions(folder, ramlResourceToFetch);

		Iterator<Float> versionSet = ramlFlolders.iterator();
		String requestVersion = new String();
		while (versionSet.hasNext()) {
			requestVersion = String.valueOf(versionSet.next());
			for (File aFile : listOfFiles) {
				if (aFile.getName().contains(".raml")) {

					String path = "file:///" + ramlResourceToFetch
							+ File.separator + aFile.getName();

					String outPutPath = outputDirectory.getAbsolutePath()
							+ File.separator + requestVersion + File.separator
							+ aFile.getName();

					String[] vArr = requestVersion.split("\\.");
					setMajorVer(Integer.parseInt(vArr[0]));
					setMinorVer(Integer.parseInt(vArr[1]));

					Raml raml = new RamlDocumentBuilder().build(path);

					raml = modifyResource(raml);

					Raml aRamlSchema = new RamlDocumentBuilder()
							.build("file:///"
									+ inputDirectory.getAbsolutePath()
									+ File.separator + "common-schema.txt");
					Raml aRamlTraits = new RamlDocumentBuilder()
							.build("file:///"
									+ inputDirectory.getAbsolutePath()
									+ File.separator + "common-traits.txt");
					List<Map<String, String>> schemaList = new ArrayList<Map<String, String>>();
					schemaList.addAll(raml.getSchemas());
					schemaList.addAll(aRamlSchema.getSchemas());
					raml.setSchemas(schemaList);
					raml.setTraits(aRamlTraits.getTraits());
					RamlEmitter emitter = new RamlEmitter();
					String dumpFromRaml = emitter.dump(raml);
					BufferedWriter writer = null;

					try {
						writer = new BufferedWriter(new FileWriter(outPutPath));
						writer.write(dumpFromRaml.toString());
						writer.close();

					} catch (FileNotFoundException e1) {
						// TODO Auto-generated catch block
						e1.printStackTrace();
					} catch (IOException e) {
						// TODO Auto-generated catch block
						e.printStackTrace();
					}
				}

			}
		}

	}

	public int getMajorVer() {
		return majorVer;
	}

	public void setMajorVer(int majorVer) {
		this.majorVer = majorVer;
	}

	public int getMinorVer() {
		return minorVer;
	}

	public void setMinorVer(int minorVer) {
		this.minorVer = minorVer;
	}

	public HashSet<Float> ramlVersions(File folder, String ramlResourceToFetch) {
		System.out.println("Input -- " + ramlResourceToFetch);
		File[] listOfFiles = folder.listFiles();
		HashSet<Float> aSet = new HashSet<Float>();
		Raml ramlObj = null;
		String description = "";
		String version = "";

		for (File aFile : listOfFiles) {
			if (aFile.getName().contains(".raml")) {
				String path = "file:///" + ramlResourceToFetch + File.separator
						+ aFile.getName();

				System.out.println("--path in ramlVersions--" + path);
				ramlObj = new RamlDocumentBuilder().build(path);
				Map<String, Resource> resourceMap = ramlObj.getResources();
				// System.out.println("---resource map--"+resourceMap);
				Resource resource = null;

				Iterator<Entry<String, Resource>> resourceItr = resourceMap
						.entrySet().iterator();

				Map.Entry<String, Resource> mapEntry1 = null;

				while (resourceItr.hasNext()) {
					mapEntry1 = resourceItr.next();

					resource = (Resource) mapEntry1.getValue();

					description = resource.getDescription();

					if (description != null) {

						if (description.indexOf('[') == -1
								|| description.indexOf(']') == -1)
							;
						else {
							String strArr1 = description.substring(
									description.indexOf('['),
									description.indexOf(']'));
							version = (strArr1.contains(" ")) ? strArr1
									.split(" ")[1] : strArr1.split(":")[1];
							// version = strArr1.split(":")[1];

							aSet.add(Float.valueOf(version));
						}// else
					}
					Map<ActionType, Action> action = resource.getActions();

					Iterator<Entry<ActionType, Action>> actionItr = action
							.entrySet().iterator();
					while (actionItr.hasNext()) {
						Map<String, Response> cloneResponse = new HashMap<String, Response>();
						Map.Entry<ActionType, Action> entry = (Entry<ActionType, Action>) actionItr
								.next();
						Action actionResponse = entry.getValue();
						description = actionResponse.getDescription();
						if (description != null) {

							if (description.indexOf('[') == -1
									|| description.indexOf(']') == -1)
								;
							else {
								String strArr1 = description.substring(
										description.indexOf('['),
										description.indexOf(']'));

								version = (strArr1.contains(" ")) ? strArr1
										.split(" ")[1] : strArr1.split(":")[1];

								aSet.add(Float.valueOf(version));
							}// else
						}
						// header code
						Map<String, Header> headerAction = actionResponse
								.getHeaders();

						Iterator<Entry<String, Header>> itrheader = headerAction
								.entrySet().iterator();
						while (itrheader.hasNext()) {
							Map.Entry<String, Header> headerMap = (Entry<String, Header>) itrheader
									.next();

							Header header = headerMap.getValue();
							if (header.getDescription() != null) {
								if (description.indexOf('[') == -1
										|| description.indexOf(']') == -1)
									;
								else {
									String strArr1 = description.substring(
											description.indexOf('['),
											description.indexOf(']'));

									version = (strArr1.contains(" ")) ? strArr1
											.split(" ")[1]
											: strArr1.split(":")[1];

									aSet.add(Float.valueOf(version));
								}// else
							}// if
						}// if

						// response code
						Map<String, Response> responseAction = actionResponse
								.getResponses();

						Iterator<Entry<String, Response>> itr1 = responseAction
								.entrySet().iterator();
						while (itr1.hasNext()) {
							Map.Entry<String, Response> responseMap = (Entry<String, Response>) itr1
									.next();

							Response response = responseMap.getValue();
							description = response.getDescription();
							if (description != null) {
								// System.out.println("---response description---"+description);
								if (description.indexOf('[') == -1
										|| description.indexOf(']') == -1)
									;
								else {
									String strArr1 = description.substring(
											description.indexOf('['),
											description.indexOf(']'));

									version = (strArr1.contains(" ")) ? strArr1
											.split(" ")[1]
											: strArr1.split(":")[1];

									aSet.add(Float.valueOf(version));
								}// else
							}
							cloneResponse.put(responseMap.getKey(),
									responseMap.getValue());

						}// while itr1

					}// while actionItr
				}// while

			}

		}
		Iterator itr = aSet.iterator();
		while (itr.hasNext()) {

			Float value = (Float) itr.next();

			File file = new File(outputDirectory.getAbsolutePath()
					+ File.separator + value);
			if (!file.isDirectory()) {
				file.mkdir();

			}

		}
		return aSet;
	}

	public Raml modifyResource(Raml ramlObj) {
		System.out
				.println("******************** Processing RAML object ********************");
		Map<String, Resource> resourceMap = ramlObj.getResources();
		Map<String, Resource> versionedResourceMap = processResourceMap(resourceMap);
		if (versionedResourceMap != null && !versionedResourceMap.isEmpty()) {
			ramlObj.setResources(versionedResourceMap);
		} else {
			ramlObj.setResources(new LinkedHashMap<String, Resource>());
		}
		return ramlObj;
	}

	public Map<String, Resource> processResourceMap(
			Map<String, Resource> resourceMap) {
		System.out
				.println("******************** Processing Resource Map object ********************");
		Map<String, Resource> versionedResourceMap = new LinkedHashMap<String, Resource>();
		if (resourceMap != null && !resourceMap.isEmpty()) {
			for (String key : resourceMap.keySet()) {
				Resource versionedResource = processResource(resourceMap
						.get(key));
				if (versionedResource != null) {
					versionedResourceMap.put(key, versionedResource);
				}
			}
		}
		return versionedResourceMap;
	}

	public Resource processResource(Resource resource) {
		System.out
				.println("******************** Processing Resource object ********************");
		Resource versionedResource = new Resource();
		if (resource.getDescription() != null) {
			verComp = getVersion(resource.getDescription().toString());
		}
		if (verComp != -1) {
			Map<String, Resource> versionedResourceMap = processResourceMap(resource
					.getResources());
			versionedResource = resource;
			processActions(versionedResource);
			if (versionedResourceMap != null && !versionedResourceMap.isEmpty()) {
				versionedResource.setResources(versionedResourceMap);
			}
		}
		return versionedResource;
	}

	public Resource processActions(Resource resource) {

		Map<ActionType, Action> action = resource.getActions();
		Map<ActionType, Action> cloneAction = new HashMap<ActionType, Action>();
		Iterator<Entry<ActionType, Action>> actionItr = action.entrySet()
				.iterator();
		while (actionItr.hasNext()) {

			Map.Entry<ActionType, Action> entry = (Entry<ActionType, Action>) actionItr
					.next();
			if (entry.getValue().getDescription() != null) {
				verComp = getVersion(entry.getValue().getDescription()
						.toString());
			}

			if (verComp != -1) {
				cloneAction.put(entry.getKey(), entry.getValue());
				processHeaders(entry.getValue());
				processResponse(entry.getValue());
				// resource.setActions(null);

			}

		}
		resource.setActions(cloneAction);
		return resource;

	}

	/*
	 * This will make version comparison
	 */

	private void processHeaders(Action action) {
		// TODO Auto-generated method stub
		Map<String, Header> headerAction = action.getHeaders();
		Map<String, Header> cloneHeader = new HashMap<String, Header>();
		Iterator<Entry<String, Header>> itr1 = headerAction.entrySet()
				.iterator();
		while (itr1.hasNext()) {
			Map.Entry<String, Header> headerMap = (Entry<String, Header>) itr1
					.next();

			Header header = headerMap.getValue();
			if (header.getDescription() != null) {
				verComp = getVersion(header.getDescription().toString());
			}
			if (verComp != -1) {
				cloneHeader.put(headerMap.getKey(), headerMap.getValue());

			}
			action.setHeaders(cloneHeader);

		}
	}

	private void processResponse(Action action) {
		// TODO Auto-generated method stub
		Map<String, Response> responseMap = action.getResponses();
		Map<String, Response> cloneResponseMap = new HashMap<String, Response>();
		Iterator<Entry<String, Response>> itr1 = responseMap.entrySet()
				.iterator();
		while (itr1.hasNext()) {
			Map.Entry<String, Response> versionedResponse = (Entry<String, Response>) itr1
					.next();

			Response response = versionedResponse.getValue();
			if (response.getDescription() != null) {
				verComp = getVersion(response.getDescription().toString());
			}
			if (verComp != -1) {
				cloneResponseMap.put(versionedResponse.getKey(),
						versionedResponse.getValue());

			}
			action.setResponses(cloneResponseMap);

		}
	}

	public int getVersion(String description) {
		int result = 0;
		int index1 = description.indexOf('[');
		int index2 = description.indexOf(']');
		if (index1 == -1 || index2 == -1)
			result = 2;
		else {
			String strArr = description.substring(description.indexOf('['),
					description.indexOf(']'));

			String version = (strArr.contains(" ")) ? strArr.split(" ")[1]
					: strArr.split(":")[1];
			String arr[] = version.split("\\.");

			firstNo = Integer.parseInt(String.valueOf(arr[0]));
			secondNo = Integer.parseInt(String.valueOf(arr[1]));

			if (majorVer < firstNo)
				result = -1;
			else if (minorVer < secondNo)
				result = -1;
			else
				result = 1;
		}

		return result;
	}
}
