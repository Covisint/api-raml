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
		

		HashSet<Float> ramlFlolders = ramlVersions(folder,
				ramlResourceToFetch);

		Iterator<Float> versionSet = ramlFlolders.iterator();
		String requestVersion = new String();
		while (versionSet.hasNext()) {
			requestVersion = String.valueOf(versionSet.next());
			for (File aFile : listOfFiles) {
				if (aFile.getName().contains(".raml")) {
				
					
					String path = "file:///" + ramlResourceToFetch +File.separator
							+ aFile.getName();

					String outPutPath = outputDirectory.getAbsolutePath() + File.separator + requestVersion
							+ File.separator + aFile.getName();

					String[] vArr = requestVersion.split("\\.");
					setMajorVer(Integer.parseInt(vArr[0]));
					setMinorVer(Integer.parseInt(vArr[1]));

					Raml raml = new RamlDocumentBuilder().build(path);

					raml = modifyResource(raml);

					raml = modifyAction(raml);
					raml = modifyHeader(raml);
					raml = modifyResponse(raml);
					
					Raml aRamlSchema = new RamlDocumentBuilder()
							.build("file:///"+inputDirectory.getAbsolutePath() + File.separator + "common-schema.txt");
					Raml aRamlTraits = new RamlDocumentBuilder()
							.build("file:///"+inputDirectory.getAbsolutePath()+ File.separator + "common-traits.txt");
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
		System.out.println("Input -- "+ramlResourceToFetch);
		File[] listOfFiles = folder.listFiles();
		HashSet<Float> aSet = new HashSet<Float>();
		Raml ramlObj = null;
		String description = "";
		String version = "";

		for (File aFile : listOfFiles) {
			if (aFile.getName().contains(".raml")) {
				String path = "file:///" + ramlResourceToFetch +File.separator
						+ aFile.getName();

				 System.out.println("--path in ramlVersions--"+path);
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

						// actionResponse.setResponses(null);
						// actionResponse.setResponses(cloneResponse);

					}// while actionItr
				}// while

			}

		}
		Iterator itr = aSet.iterator();
		while (itr.hasNext()) {

			Float value = (Float) itr.next();

			File file = new File(outputDirectory.getAbsolutePath() + File.separator + value);
			if (!file.isDirectory()) {
				file.mkdir();

			}

		}
		return aSet;
	}

	/*
	 * This method check Response description for version
	 */

	public Raml modifyResponse(Raml ramlObj) {
		Map<String, Resource> resourceMap = ramlObj.getResources();
		Resource resource = null;

		Iterator<Entry<String, Resource>> resourceItr = resourceMap.entrySet()
				.iterator();

		Map.Entry<String, Resource> mapEntry1 = null;

		while (resourceItr.hasNext()) {
			mapEntry1 = resourceItr.next();

			resource = (Resource) mapEntry1.getValue();

			Map<ActionType, Action> action = resource.getActions();

			Iterator<Entry<ActionType, Action>> actionItr = action.entrySet()
					.iterator();
			while (actionItr.hasNext()) {
				Map<String, Response> cloneResponse = new HashMap<String, Response>();
				Map.Entry<ActionType, Action> entry = (Entry<ActionType, Action>) actionItr
						.next();
				Action actionResponse = entry.getValue();
				Map<String, Response> responseAction = actionResponse
						.getResponses();

				Iterator<Entry<String, Response>> itr1 = responseAction
						.entrySet().iterator();
				while (itr1.hasNext()) {
					Map.Entry<String, Response> responseMap = (Entry<String, Response>) itr1
							.next();

					Response response = responseMap.getValue();
					if (response.getDescription() != null) {
						verComp = getVersion(response.getDescription()
								.toString());
					}
					if (verComp != -1) {
						cloneResponse.put(responseMap.getKey(),
								responseMap.getValue());

					}

				}

				actionResponse.setResponses(null);
				actionResponse.setResponses(cloneResponse);

			}

		}

		return ramlObj;

	}

	/*
	 * This method check header description for version
	 */
	public Raml modifyHeader(Raml ramlObj) {
		Map<String, Resource> resourceMap = ramlObj.getResources();
		Resource resource = null;

		Iterator<Entry<String, Resource>> resourceItr = resourceMap.entrySet()
				.iterator();

		Map.Entry<String, Resource> mapEntry1 = null;

		while (resourceItr.hasNext()) {
			mapEntry1 = resourceItr.next();

			resource = (Resource) mapEntry1.getValue();

			Map<ActionType, Action> action = resource.getActions();

			Iterator<Entry<ActionType, Action>> actionItr = action.entrySet()
					.iterator();
			while (actionItr.hasNext()) {
				Map<String, Header> cloneHeader = new HashMap<String, Header>();
				Map.Entry<ActionType, Action> entry = (Entry<ActionType, Action>) actionItr
						.next();
				Action actionHeader = entry.getValue();
				Map<String, Header> headerAction = actionHeader.getHeaders();

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
						cloneHeader.put(headerMap.getKey(),
								headerMap.getValue());

					}

				}

				actionHeader.setHeaders(null);
				actionHeader.setHeaders(cloneHeader);

			}

		}

		return ramlObj;

	}

	/*
	 * This method check Action description for version
	 */

	public Raml modifyAction(Raml ramlObj) {

		Map<String, Resource> resourceMap = ramlObj.getResources();
		Resource resource = null;

		// while(resourceMap.size()!=0){
		Iterator<Entry<String, Resource>> resourceItr = resourceMap.entrySet()
				.iterator();

		Map.Entry<String, Resource> mapEntry1 = null;

		while (resourceItr.hasNext()) {
			mapEntry1 = resourceItr.next();

			resource = (Resource) mapEntry1.getValue();

			Map<ActionType, Action> action = resource.getActions();

			Iterator<Entry<ActionType, Action>> actionItr = action.entrySet()
					.iterator();
			while (actionItr.hasNext()) {

				Map.Entry<ActionType, Action> entry = (Entry<ActionType, Action>) actionItr
						.next();
				if (entry.getValue().getDescription() != null) {
					verComp = getVersion(entry.getValue().getDescription()
							.toString());
				}
				Map<ActionType, Action> cloneAction = new HashMap<ActionType, Action>();
				if (verComp != -1) {
					cloneAction.put(entry.getKey(), entry.getValue());
					resource.setActions(null);
					resource.setActions(cloneAction);
				}

			}

		}

		return ramlObj;

	}

	/*
	 * This method check Resource description for version
	 */

	public Raml modifyResource(Raml ramlObj) {
		Map<String, Resource> resourceMap = ramlObj.getResources();

		Resource resource = null;

		Map<String, Resource> cloneResource = new HashMap<String, Resource>();
		@SuppressWarnings("unused")
		int size = resourceMap.size();

		ramlObj.setResources(null);
		while (resourceMap.size() != 0) {
			Iterator<Entry<String, Resource>> itr2 = resourceMap.entrySet()
					.iterator();

			Map.Entry<String, Resource> mapEntry1 = null;
			while (itr2.hasNext()) {
				mapEntry1 = itr2.next();

				resource = (Resource) mapEntry1.getValue();
				if (resource.getDescription() != null) {
					verComp = getVersion(resource.getDescription().toString());
				}

				if (verComp != -1) {
					cloneResource.put(mapEntry1.getKey().toString(), resource);
				}

			}
			resourceMap = resource.getResources();
			resource.setResources(null);

		}

		ramlObj.setResources(cloneResource);

		return ramlObj;

	}

	/*
	 * This will make version comparison
	 */

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
